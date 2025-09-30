[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope = 'Function', Target = 'Warp-*', Justification = 'Warp-* functions are ours')]
param()

# Wrap things in a module to avoid cluttering the global scope. We assign it to '$null' to suppress
# the console output from creating the module.
# NOTE: If you do need a function to be global and also have access to variables in this scope, add
# the function name to the 'Export-ModuleMember' call at the end.
$null = New-Module -Name Warp-Module -ScriptBlock {
    # Byte sequence used to signal the start of an OSC for Warp JSON messages.
    $oscStart = "$([char]0x1b)]9278;"

    # Appended to $oscStart to signal that the following message is JSON-encoded.
    $oscJsonMarker = 'd'

    $oscParamSeparator = ';'

    # Byte used to signal the end of an OSC for Warp JSON messages.
    $oscEnd = "$([char]0x07)"

    # Writes a hex-encoded JSON message to the PTY.
    function Warp-Send-JsonMessage([System.Collections.Hashtable]$table) {
        $json = ConvertTo-Json -InputObject $table -Compress
        # Sends a message to the controlling terminal as an OSC control sequence.
        # TODO(CORE-2718): Determine if we need to hex encode the payload.
        # Note that because the JSON string may contain characters that we don't control (including
        # unicode), we encode it as hexadecimal string to avoid prematurely calling unhook if
        # one of the bytes in JSON is 9c (ST) or other (CAN, SUB, ESC).
        $encodedMessage = Warp-Encode-HexString $json
        Write-Host -NoNewline "$oscStart$oscJsonMarker$oscParamSeparator$encodedMessage$oscEnd"
    }

    # This script block contains commands and constants that are needed in background threads.
    # If you want to be able to use it in a background thread, stick it in this block
    $warpCommon = {
        # OSC used to mark the start of in-band command output.
        #
        # Printable characters received this OSC and oscEndGeneratorOutput are parsed and handled as
        # output for an in-band command.
        $oscStartGeneratorOutput = "$([char]0x1b)]9277;A$oscEnd"

        # OSC used to mark the end of in-band command output.
        #
        # Printable characters received between oscStartGeneratorOutput and this are parsed and
        # handled as output for an in-band command.
        $oscEndGeneratorOutput = "$([char]0x1b)]9277;B$oscEnd"

        $oscResetGrid = "$([char]0x1b)]9279$oscEnd"

        function Warp-Send-ResetGridOSC() {
            Write-Host -NoNewline $oscResetGrid
        }

        # Safely attempt to get Node.js version if available. Avoid literal 'node' invocation
        # to satisfy PSUseCompatibleCommands across target platforms.
        function Warp-TryGet-NodeVersion {
            try {
                $cmd = Get-Command -CommandType Application node 2>$null
                if ($null -eq $cmd) { return '' }
                $nv = & $cmd.Source --version 2>$null
                if ($null -ne $nv -and "$nv" -ne '') {
                    return $nv
                }
            } catch {
                # Log at verbose level so normal users are not spammed, but the catch is not empty.
                Write-Verbose "node --version failed: $($_.Exception.Message)"
            }
            return ''
        }

        # Encode a string as hex-encoded UTF-8.
        function Warp-Encode-HexString([string]$str) {
            [BitConverter]::ToString([System.Text.Encoding]::UTF8.GetBytes($str)).Replace('-', '')
        }

        # Hex-encodes the given argument and writes it to the PTY, wrapped in the OSC
        # sequences for generator output.
        #
        # The payload of the OSC is "<content_length>;<hex-encoded content>".
        function Warp-Send-GeneratorOutputOsc {
            param([string]$message)

            $hexEncodedMessage = Warp-Encode-HexString $message
            $byteCount = [System.Text.Encoding]::ASCII.GetByteCount($hexEncodedMessage)

            Write-Host -NoNewline "$oscStartGeneratorOutput$byteCount;$hexEncodedMessage$oscEndGeneratorOutput"
            Warp-Send-ResetGridOSC
        }

        # Do not run this in the main thread. It mucks around with some env vars
        function Warp-Run-InBandGenerator {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'We actually need it')]
            param([string]$commandId, [string]$command)

            try {
                # We do not have a good way to simultaneously capture
                # the command status $? and the command output of our command.
                # this is because Invoke-Expression will always set $? to true.
                # To get around this, we append a small bit of code to the original
                # command that makes Invoke-Expression throw if the last command
                # did not succeed.
                $modifiedCommand = "$command" + '; if (-Not $?) { throw }'

                # We set this immediately before running Invoke-Expression,
                # that way it will default to 0
                $LASTEXITCODE = 0

                # Note: parens are important here. Without them
                # parsing order gets messed up on the 2>&1
                $rawOutput = Invoke-Expression -Command "$modifiedCommand" 2>&1
                $exitCode = $LASTEXITCODE

                # If the generator command returns multi-line output,
                # we make sure to join the lines together with a newline, so
                # they are properly parsed by warp
                $stringifiedOutput = $rawOutput -join "$([char]0x0a)"

                # This is a best-effort attempt to get an error code.
                # We cannot duplicate our error code logic from Warp-Precmd
                # b/c Invoke-Expression will swallow the value of $? and always
                # return true. So we do our best to return a legit error code
                Write-Output "$commandId;$stringifiedOutput;$exitCode"
            } catch {
                # This catches a terminating error (ex: entering a command that does not exist)
                # In this case, we return an error code of 1
                Write-Output "$commandId;1;"
            }
        }
    }

    # Load the Warp Common functions in the current session
    . $warpCommon

    # Implementation copied from here:
    # https://stackoverflow.com/questions/70977897/get-epoch-time-with-fractions-of-a-second-powershell
    function Get-EpochTime {
        [decimal]([DateTime]::UtcNow - [DateTime]::new(1970, 1, 1, 0, 0, 0, 0)).Ticks / 1e7
    }

    function Warp-Bootstrapped {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'WARP_BOOTSTRAPPED', Justification = 'False positive as we are assigning to global')]
        param([decimal]$rcStartTime, [decimal]$rcEndTime)

        $envVarNames = (Get-ChildItem env: | Select-Object -ExpandProperty Name | ForEach-Object { 'env:' + $_ }) + `
        (Get-Variable | Select-Object -ExpandProperty Name) -join ' '
        $aliasesRaw = Get-Command -CommandType Alias | Select-Object -ExpandProperty DisplayName
        $aliases = $aliasesRaw -join [Environment]::NewLine
        $functionNamesRaw = Get-Command -CommandType Function | Where-Object { -not $_.Name.StartsWith('Warp') } | Select-Object -ExpandProperty Name
        $functionNames = $functionNamesRaw -join [Environment]::NewLine
        $builtinsRaw = Get-Command -CommandType Cmdlet | Select-Object -ExpandProperty Name
        $builtins = $builtinsRaw -join [Environment]::NewLine
        $shellVersion = $PSVersionTable.PSVersion.ToString()
        # PowerShell wasn't cross-platform until version 6. Anything before that is definitely on Windows.
        $osCategory = if ($PSVersionTable.PSVersion.Major -le 5) {
            'Windows'
        } elseif ($IsLinux) {
            'Linux'
        } elseif ($IsMacOS) {
            'MacOS'
        } elseif ($IsWindows) {
            'Windows'
        } else {
            ''
        }

        # We do not have an equivalent to 'compgen -k' here, so we are dropping
        # in a hardcoded list. List is take from
        # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_reserved_words?view=powershell-7.4
        $PSKeywords = @(
            'begin', 'break', 'catch', 'class', 'continue', 'data', 'define',
            'do', 'dynamicparam', 'else', 'elseif', 'end', 'enum', 'exit',
            'filter', 'finally', 'for', 'foreach', 'from', 'function', 'hidden',
            'if', 'in', 'param', 'process', 'return', 'static', 'switch', 'throw',
            'trap', 'try', 'until', 'using', 'var', 'while', 'inlinescript',
            'parallel', 'sequence', 'workflow'
        ) -join [environment]::NewLine

        $linuxDistribution = $null
        if ($osCategory -eq 'Linux') {
            $osReleaseFile = if (Test-Path -Path '/etc/os-release') {
                '/etc/os-release'
            } elseif (Test-Path -Path '/usr/lib/os-release') {
                '/usr/lib/os-release'
            } else {
                $null
            }
            if ($null -ne $osReleaseFile) {
                # This is meant to be the equivalent to the bash command
                # cat $os_release_file | sed -nE 's/^NAME="(.*)"$/\1/p'. We filter
                # specifically for the Name= line of the osRelease file, and then
                # pull out the OS name
                $linuxDistribution = switch -Regex -File $osReleaseFile {
                    '^\s*NAME="(.*)"' {
                        $Matches[1]
                        break
                    }
                }
            }
        }

        # TODO(PLAT-681) - finish the information here
        # for keywords, see 'Get-Help about_Language_Keywords'
        $bootstrappedMsg = @{
            hook = 'Bootstrapped'
            value = @{
                histfile = $(Get-PSReadLineOption).HistorySavePath
                shell = 'pwsh'
                home_dir = "$HOME"
                path = $env:PATH
                editor = "$env:EDITOR"
                env_var_names = $envVarNames
                abbreviations = ''
                aliases = $aliases
                function_names = $functionNames
                builtins = $builtins
                keywords = "$PSKeywords"
                shell_version = $shellVersion
                shell_options = ''
                rcfiles_start_time = "$rcStartTime"
                rcfiles_end_time = "$rcEndTime"
                shell_plugins = ''
                os_category = $osCategory
                linux_distribution = "$linuxDistribution"
            }
        }
        Warp-Send-JsonMessage $bootstrappedMsg
        $global:WARP_BOOTSTRAPPED = 1
    }

    function Warp-Preexec([string]$command) {
        $HOST.UI.RawUI.WindowTitle = $command
        $preexecMsg = @{
            hook = 'Preexec'
            value = @{
                command = $command
            }
        }
        Warp-Send-JsonMessage $preexecMsg
        Warp-Send-ResetGridOSC

        # If this preexec is called for user command, kill ongoing generator command jobs and clean
        # up the bookkeeping temp files used to bookkeep.
        if (-not "$command" -match '^Warp-Run-GeneratorCommand') {
            Warp-Stop-ActiveThread
        }

        # Clean up any completed warp jobs so they do not show up on the user's 'get-job'
        # comands
        Warp-Clean-CompletedThread

        # Remove any instance of the 'Warp-Run-GeneratorCommand' call from the user's history
        Clear-History -CommandLine 'Warp-Run-GeneratorCommand*'
    }

    function Warp-Finish-Update([string]$updateId) {
        $updateMsg = @{
            hook = 'FinishUpdate'
            value = @{
                update_id = $updateId
            }
        }
        Warp-Send-JsonMessage $updateMsg
    }

    function Warp-Handle-DistUpgrade {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'We actually need it')]
        param([string]$sourceFileName)

        $aptConfig = Get-Command -Type Application apt-config | Select-Object -First 1
        & $aptConfig shell '$aptSourcesDir' 'Dir::Etc::sourceparts/d' | Invoke-Expression

        $sourceFilePath = "${aptSourcesDir}${sourceFileName}"

        if (
            -not (Test-Path "${sourceFilePath}.list") -and
            -not (Test-Path "${sourceFilePath}.sources") -and
            (Test-Path "${sourceFilePath}.list.distUpgrade")
        ) {
            # DO NOT DO THIS. We should never run a command for user with 'sudo'. The only reason this
            # is safe here is because we insert this function into the input for the user to determine
            # if they want to execute (we never run it on their behalf without their permission).
            sudo cp "${sourceFilePath}.list.distUpgrade" "${sourceFilePath}.list"
        }
    }

    # We need this for a few reasons
    # 1. We need to make sure the environment variable GIT_OPTIONAL_LOCKS=0.
    #    See https://stackoverflow.com/questions/71836872/git-environment-variables-on-powershell-on-windows
    #    for why this is complicated
    # 2. We need to make sure that we are calling the Application git, and not
    #    an alias or cmdlet named Git
    #
    # NOTE: Inlining this call in the function has a weird side effect of outputing
    #    an escape sequence '^[i'. Since it made it more convenient to have a wrapper
    #    function anyway, I have not investigated this, but in case someone is working
    #    on this in the future, beware attempting to inline this function.
    function Warp-Git {
        $GIT_OPTIONAL_LOCKS = $env:GIT_OPTIONAL_LOCKS
        $env:GIT_OPTIONAL_LOCKS = 0
        try {
            &(Get-Command -CommandType Application git | Select-Object -First 1) $args
        } finally {
            $env:GIT_OPTIONAL_LOCKS = $GIT_OPTIONAL_LOCKS
        }
    }

    # Helper function that resets the values of '$?' and
    # $LASTEXITCODE. Note that it cannot force '$?' to $true
    # if it is currently $false
    #
    # Make sure when you call this you call it with -ErrorAction SilentlyContinue
    # or it will print out error information when it is invoked.
    function Warp-Restore-ErrorStatus {
        [CmdletBinding()]
        param([boolean]$status, [int]$code)

        $global:LASTEXITCODE = $code
        if ($status -eq $false) {
            $PSCmdlet.WriteError([System.Management.Automation.ErrorRecord]::new(
                    [Exception]::new("$([char]0x00)"),
                    'warp-reset-error',
                    [System.Management.Automation.ErrorCategory]::NotSpecified,
                    $null
                ))
        }
    }

    # Tracks whether or not powershell is unable to find a command.
    # See the $ExecutionContext.InvokeCommand.CommandNotFoundAction where it is set to $true,
    # and both $ExecutionContext.InvokeCommand.PostCommandLookupAction and Warp-Precmd where
    # it is set to $false.
    $script:commandNotFound = $false

    function Warp-Configure-PSReadLine {
        # Set-PSReadLineKeyHandler is the PowerShell equivalent of zsh's bindkey.
        Set-PSReadLineKeyHandler -Chord 'Alt+2' -Function BackwardDeleteLine

        # Input reporting. Note that ESC-1 is used instead of ESC-i as for all other shells. This
        # is because PowerShell on Windows does some virtual key code translation which depends on
        # the selected input language. On languages without an "i" on any key, this translation
        # fails and the binding gets dropped.
        Set-PSReadLineKeyHandler -Chord 'Alt+1' -ScriptBlock {
            $inputBuffer = $null
            $cursorPosition = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$inputBuffer, [ref]$cursorPosition)
            $inputBufferMsg = @{
                hook = 'InputBuffer'
                value = @{
                    buffer = $inputBuffer
                }
            }
            Warp-Send-JsonMessage $inputBufferMsg
            [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteLine()
            # This is triggered after precmd, so output here goes to the "early output" handler,
            # i.e. the background block. This clears the line the cursor is on. We clear it out b/c
            # at this point, the only stuff in the early output handler is typeahead, and that
            # shouldn't be displayed in a background block at all. It should be in the input
            # editor. Most shells will automatically emit the correct ANSI escape codes to delete
            # the contents of the early output handler when we kill the line editor's buffer.
            # However, PowerShell doesn't do this correctly due to cursor position mismatch. So,
            # we do it manually here instead.
            Write-Host -NoNewline "$([char]0x1b)[2K"
        }

        # Sets the prompt mode to custom prompt (PS1)
        # Is the equivalent of warp_change_prompt_modes_to_ps1 in other shells
        Set-PSReadLineKeyHandler -Chord 'Alt+p' -ScriptBlock {
            $env:WARP_HONOR_PS1 = '1'
            Warp-Redraw-Prompt
        }

        # Sets the prompt mode to warp prompt
        # Is the equivalent of warp_change_prompt_modes_to_warp_prompt in other shells
        Set-PSReadLineKeyHandler -Chord 'Alt+w' -ScriptBlock {
            $env:WARP_HONOR_PS1 = '0'
            Warp-Redraw-Prompt
        }

        Set-PSReadLineOption -AddToHistoryHandler {
            param([string]$line)

            if ($line -match '^Warp-Run-GeneratorCommand') {
                return $false
            }
            return $true
        }

        Warp-Disable-PSPrediction
    }

    # Force use of the Inline PredictionViewStyle. The ListView style can occassionally cause some
    # flickering when using Warp and it doesn't matter what the value of this setting is because
    # Warp has its own input editor.
    function Warp-Disable-PSPrediction {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCommands', '', Justification = 'Errors are ignored')]
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '', Justification = 'Errors expected')]
        param()
        try {
            Set-PSReadLineOption -PredictionSource None
            Set-PSReadLineOption -PredictionViewStyle InlineView
        } catch {
        }
    }

    function Warp-Precmd {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPositionalParameters', '', Justification = 'Warp-Git should use positionals')]
        param([bool]$status, [int]$code)
        # Our logic here is:
        #
        # if $status == True, always set $exitCode to 0
        # if $status == False and $script:commandNotFound is true
        #     (meaning we triggered the CommandNotFoundHandler), set $exitCode to 127
        # if $status == False and $LASTEXITCODE is zero, set $exitCode to 1
        # else set $exitCode to $LASTEXITCODE
        #
        # Note that this is not going to be 100% accurate, as some cmdlets will fail
        # without setting a $LASTEXITCODE, meaning the $LASTEXITCODE will be stale.
        $warpCommandNotFound = $script:commandNotFound
        $script:commandNotFound = $false

        $exitCode = if ($status) {
            0
        } elseif ($warpCommandNotFound) {
            127
        } elseif ($code -eq 0) {
            1
        } else {
            $code
        }

        $newTitle = (Get-Location).Path
        # Replace the literal home dir with a tilde.
        if ($newTitle.StartsWith($HOME)) {
            $newTitle = '~' + $newTitle.Substring($HOME.length)
        }
        $HOST.UI.RawUI.WindowTitle = $newTitle

        $blockId = $script:nextBlockId++
        $commandFinishedMsg = @{
            hook = 'CommandFinished'
            value = @{
                exit_code = $exitCode
                next_block_id = "precmd-${global:_warpSessionId}-$blockId"
            }
        }
        Warp-Send-JsonMessage $commandFinishedMsg
        Warp-Send-ResetGridOSC

        Warp-Configure-PSReadLine

        # If this is being called for a generator command, short circuit and send an unpopulated
        # precmd payload (except for pwd), since we don't re-render the prompt after generator commands
        # are run.
        if ($script:generatorCommand -eq $true) {
            # TODO(CORE-2639): handle user PreCmds here

            $script:generatorCommand = $false

            $precmdMsg = @{
                hook = 'Precmd'
                value = @{
                    pwd = ''
                    ps1 = ''
                    git_branch = ''
                    virtual_env = ''
                    conda_env = ''
                    session_id = $global:_warpSessionId
                    is_after_in_band_command = $true
                }
            }
            Warp-Send-JsonMessage $precmdMsg
        } else {
            # TODO(CORE-2678): Figure out resetting bindkeys here

            $virtualEnv = ''
            $condaEnv = ''
            $kubeConfig = ''
            $gitBranch = ''
            $nodeVersion = ''

            # Only fill these fields once we've finished bootstrapping, as the
            # blocks created during the bootstrap process don't have visible
            # prompts, and we don't want to invoke 'git' before we've sourced the
            # user's rcfiles and have a fully-populated PATH.
            if ($global:WARP_BOOTSTRAPPED -eq 1) {
                if (Test-Path env:VIRTUAL_ENV) {
                    $virtualEnv = $env:VIRTUAL_ENV
                }
                if (Test-Path env:CONDA_DEFAULT_ENV) {
                    $condaEnv = $env:CONDA_DEFAULT_ENV
                }
                if (Test-Path env:KUBECONFIG) {
                    $kubeConfig = $env:KUBECONFIG
                }

                # Compute Node.js version if node is available and we're in a Node project within a Git repo.
                $hasNodeCommand = Get-Command -CommandType Application node 2>$null
                if ($hasNodeCommand) {
                    try {
                        # Walk up from the current directory to find a package.json
                        $dir = Get-Item -LiteralPath (Get-Location).Path
                        $foundPackageJson = $false
                        $packageJsonDir = $null
                        while ($null -ne $dir) {
                            $candidate = Join-Path $dir.FullName 'package.json'
                            if (Test-Path -LiteralPath $candidate) {
                                $foundPackageJson = $true
                                $packageJsonDir = $dir.FullName
                                break
                            }
                            $dir = $dir.Parent
                        }

                        if ($foundPackageJson) {
                            # Verify package.json resides within a Git repository by walking up to find a .git directory
                            $probe = Get-Item -LiteralPath $packageJsonDir
                            $inGitRepo = $false
                            while ($null -ne $probe) {
                                if (Test-Path -LiteralPath (Join-Path $probe.FullName '.git')) {
                                    $inGitRepo = $true
                                    break
                                }
                                $probe = $probe.Parent
                            }

                            if ($inGitRepo) {
                                $nodeVersion = Warp-TryGet-NodeVersion
                            }
                        }
                    } catch {
                        # Log at verbose level so the catch block is not empty and diagnostics are available when needed.
                        Write-Verbose "Failed to compute Node.js context: $($_.Exception.Message)"
                    }
                }

                # We do not inline $hasGitCommand b/c the linter does not like seeing '>'
                # in an if statement; it thinks we are trying to do -gt incorrectly.
                # Since this is a good warning and we do not want to turn off this lint rule,
                # we do a little indirection here
                $hasGitCommand = Get-Command -CommandType Application git 2>$null
                if ($hasGitCommand) {
                    # This is deliberately not using || b/c || only works in Powershell >=7
                    $gitBranchTmp = Warp-Git symbolic-ref --short HEAD 2>$null
                    if ($null -eq $gitBranchTmp) {
                        $gitBranchTmp = Warp-Git rev-parse --short HEAD 2>$null
                    }
                    if ($null -ne $gitBranchTmp) {
                        $gitBranch = $gitBranchTmp
                    }
                }
            }

            $honor_ps1 = "$env:WARP_HONOR_PS1" -eq '1'

            $precmdMsg = @{
                hook = 'Precmd'
                value = @{
                    pwd = (Get-Location).Path
                    # TODO(PLAT-687) - honor the PS1
                    ps1 = ''
                    honor_ps1 = $honor_ps1
                    # TODO(PLAT-687) - pwsh does not by default support rprompt, but
                    # oh-my-posh does. If there is a way to easily extract the oh-my-posh
                    # rprompt, we might want to use it here
                    rprompt = ''
                    git_branch = $gitBranch
                    virtual_env = $virtualEnv
                    conda_env = $condaEnv
                    node_version = $nodeVersion
                    session_id = $global:_warpSessionId
                    kube_config = $kubeConfig
                }
            }
            Warp-Send-JsonMessage $precmdMsg
        }
    }

    $script:inBandCommandCount = 0
    $script:threadInner = @{}
    $script:threadOuter = @{}

    # The inner runspace pool maintains a pool of runspaces that can execute
    # arbitrary commands against the user's current environment without
    # writing to the screen. Initialize to minimum of 10 runspaces
    # to handle double the number of context chips we currently have
    # that use in-band commands
    $script:innerRunspacePool = [runspacefactory]::CreateRunspacePool(10, 20)
    $script:innerRunspacePool.ApartmentState = [System.Threading.ApartmentState]::STA
    $script:innerRunspacePool.ThreadOptions = 'ReuseThread'
    $script:innerRunspacePool.Open() | Out-Null

    # The outer runspace pool maintains a pool of runspaces that
    # share the same host as the user's session. This allows them
    # to send OSC commands via Write-Host. These outer runspaces
    # handle receiving results from the inner runspaces and formatting
    # those results into OSCs.
    # Initialized to minimum of 5 runspaces since we currently do not
    # run more than one outer command at a time.
    $script:outerRunspacePool = [runspacefactory]::CreateRunspacePool(5, 10, $Host)
    $script:outerRunspacePool.ApartmentState = [System.Threading.ApartmentState]::STA
    $script:outerRunspacePool.ThreadOptions = 'ReuseThread'
    $script:outerRunspacePool.Open() | Out-Null

    class WarpGeneratorCommand {
        [string]$CommandId
        [string]$Command
    }

    function Warp-Run-GeneratorCommandImpl {
        param(
            [WarpGeneratorCommand[]]$commands
        )

        $jobNumber = $script:inBandCommandCount++

        $batchNumber = 0
        $jobs = $commands | ForEach-Object {
            $commandId = $_.CommandId
            $command = $_.Command

            # Creates a powershell instance on one of our inner runspaces
            # that first loads all the warp common functions, and then
            # executes the in-band generator in the current directory
            $ps = [powershell]::Create()
            $ps.RunspacePool = $script:innerRunspacePool
            $ps.AddScript($warpCommon) | Out-Null
            $ps.AddScript({
                    param([string]$loc, [string]$commandId, [string]$command)
                    Set-Location $loc
                    Warp-Run-InBandGenerator -commandId $commandId -command "$command"
                }).AddParameters(@($PWD.Path, $commandId, "$command")) | Out-Null

            $script:threadInner["Warp-Inner-$jobNumber-$batchNumber"] = $psInner
            $batchNumber++

            @{
                commandId = $commandId
                ps = $ps
            }
        }

        # Creates the outer job, which waits on all the inner jobs
        # and then sends the results back to Warp via OSC
        $psOuter = [powershell]::Create()
        $psOuter.RunspacePool = $script:outerRunspacePool
        $psOuter.AddScript($warpCommon) | Out-Null
        $psOuter.AddScript({
                param([object[]]$jobs)

                $invocations = $jobs | ForEach-Object {
                    @{
                        commandId = $_.commandId
                        ps = $_.ps
                        async = $_.ps.BeginInvoke()
                    }
                }

                $invocations | ForEach-Object {
                    $commandId = $_.commandId
                    $ps = $_.ps
                    $async = $_.async

                    $output = "$commandId;1;"

                    try {
                        $output = $ps.EndInvoke($async)
                    } catch {
                        $output = "$commandId;1;"
                    }
                    Warp-Send-GeneratorOutputOsc $output
                }
            }).AddParameters(@($jobs)) | Out-Null

        # Note: we are beginning the invocation, but are explicitly
        # not stopping it as we do not want to block the main thread.
        $async = $psOuter.BeginInvoke()

        $script:threadOuter["Warp-Outer-$jobNumber"] = $psOuter
    }

    function Warp-Stop-ActiveThread {
        $script:threadInner.values | ForEach-Object {
            $_.Stop()
        }
    }

    function Warp-Clean-CompletedThread {
        # Powershell instances states > 2 are terminal.
        # See https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.psinvocationstate
        if ($script:threadInner.Count -gt 0) {
            $script:threadInner.Keys.Clone() | ForEach-Object {
                $thread = $script:threadInner[$_]
                $state = [int]$thread.InvocationStateInfo.State
                if ($state -gt 2) {
                    $thread.Dispose()
                    $script:threadInner.Remove($_)
                }
            }
        }
        if ($script:threadOuter.Count -gt 0) {
            $script:threadOuter.Keys.Clone() | ForEach-Object {
                $thread = $script:threadOuter[$_]
                $state = [int]$thread.InvocationStateInfo.State
                if ($state -gt 2) {
                    $thread.Dispose()
                    $script:threadOuter.Remove($_)
                }
            }
        }
    }

    function Warp-Run-GeneratorCommand {
        [CmdletBinding()]
        param(
            [parameter(ValueFromRemainingArguments = $true)][string[]]$passedArgs
        )

        $status = $?
        $code = $global:LASTEXITCODE

        # Setting this environment variable prevents warp_precmd from emitting the
        # 'Block started' hook to the Rust app.
        $script:generatorCommand = $true

        # TODO(CORE-2639) If we ever start supporting user precmd or preexec
        # (which doesn't really exist in powershell, but :shrug:), we need
        # to properly handle them here like we do in bashzshfish

        # Converts the passed in args to WarpGeneratorCommand objects to group them together
        # note that if an odd number of arguments is passed in, the last arg will be silently ignored
        [WarpGeneratorCommand[]] $jobs = @()
        for ($i = 0; $i -lt $passedArgs.Length; $i += 2) {
            $commandId = $passedArgs[$i]
            $command = $passedArgs[$i + 1]

            if ($null -ne $command) {
                $jobs += [WarpGeneratorCommand]@{
                    commandId = $commandId
                    command = $command
                }
            }
        }

        try {
            Warp-Run-GeneratorCommandImpl -commands $jobs
        } finally {
            # NOTE: for some reason the Warp-Restore-ErrorStatus does not work
            # for this function, so we are inlining it in here.
            $global:LASTEXITCODE = $code
            if ($status -eq $false) {
                $PSCmdlet.WriteError([System.Management.Automation.ErrorRecord]::new(
                        [Exception]::new("$([char]0x00)"),
                        'warp-reset-error',
                        [System.Management.Automation.ErrorCategory]::NotSpecified,
                        $null
                    ))
            }
        }

    }

    function Warp-Render-Prompt {
        param([bool]$status, [int]$code, [bool]$isGeneratorCommand)

        # If this is a generator command, we do not want to recompute
        # the prompt, and instead want to return the original prompt.
        if ($isGeneratorCommand) {
            return $script:lastRenderedPrompt
        }

        # Reset error code for computing prompt
        $global:LASTEXITCODE = $code
        if (-not $status) {
            # Set's $? to false for the next function call,
            # so it can be used for computing the prompt
            Write-Error '' -ErrorAction Ignore
        }

        # Compute prompt and cache it as the last rendered prompt
        $basePrompt = & $global:_warpOriginalPrompt
        $script:lastRenderedPrompt = $basePrompt

        return $basePrompt
    }

    function Warp-Decorate-Prompt {
        param([string]$basePrompt)

        $e = "$([char]0x1b)"

        # Wrap prompt in Prompt Marker OSCs
        $startPromptMarker = "$e]133;A$oscEnd"
        $startRPromptMarker = "$e]133;P;k=r$oscEnd"
        if ("$env:WARP_HONOR_PS1" -eq '0') {
            $endPromptMarker = "$e]133;B$oscEnd$oscResetGrid"
        } else {
            $endPromptMarker = "$e]133;B$oscEnd"
        }
        $decoratedPrompt = "$basePrompt"

        # We only redecorate the prompt if it is not already decorated
        if (-not ($basePrompt -match '^\x1b]133;A')) {
            $decoratedPrompt = "$startPromptMarker$basePrompt$endPromptMarker"
            # Special case for ohmyposh that prints an rprompt. If it matches the format of ohmyposh
            # rprompt, we properly parse it into lprompt and rprompt
            if ($basePrompt -match '(?<lprompt>.*)[\x1b]7\s*(?<rprompt>\S.*)[\x1b]8') {
                $lprompt = $Matches.lprompt
                $rprompt = $Matches.rprompt
                $decoratedPrompt = "$startPromptMarker$lprompt$endPromptMarker${e}7$startRPromptMarker$rprompt$endPromptMarker${e}8"
            }
        }

        return $decoratedPrompt
    }

    $script:dontRunPrecmdForPrompt = $false
    # Redraws the prompt. Since our prompt also triggers the precmd hook
    # we need to signal that we do not want that to happen
    function Warp-Redraw-Prompt {
        param()

        $y = $Host.UI.RawUI.CursorPosition.Y
        $script:dontRunPrecmdForPrompt = $true
        try {
            [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt($null, $y)
        } finally {
            $script:dontRunPrecmdForPrompt = $false
        }
    }

    function Warp-Prompt {
        param()

        # We need to capture all the data related to exit codes and such
        # as soon as possible for a few reasons
        # 1. We need to make sure that these values are as fresh as possible
        #    and are not impacted by our Warp- functions
        # 2. After we finish running Warp-Precmd and Warp-Render-Prompt, we want to set these values
        #    back to what they were originally
        $status = $?
        $code = $LASTEXITCODE
        $isGeneratorCommand = [bool]($script:generatorCommand -eq $true)

        if ($script:dontRunPrecmdForPrompt -ne $true) {
            Warp-Precmd -status $status -code $code
        }

        $script:preexecHandled = $false

        $renderedPrompt = Warp-Render-Prompt -status $status -code $code -isGeneratorCommand $isGeneratorCommand
        $decoratedPrompt = Warp-Decorate-Prompt -basePrompt $renderedPrompt
        $extraLines = ($decoratedPrompt -split "$([char]0x0a)").Length - 1
        Set-PSReadLineOption -ExtraPromptLineCount $extraLines

        # NOTE: Because we are in the prompt, we do not need to reset
        # the $? automatic variable (apparently $prompt does not impact it).
        # However, we do need to reset the LASTEXITCODE. If we ever refactor
        # this to not use the prompt, then watch out for $?
        $global:LASTEXITCODE = $code

        return $decoratedPrompt
    }

    if ((Test-Path env:WARP_INITIAL_WORKING_DIR) -and -not [String]::IsNullOrEmpty($env:WARP_INITIAL_WORKING_DIR)) {
        Set-Location $env:WARP_INITIAL_WORKING_DIR 2> $null
        Remove-Item -Path env:WARP_INITIAL_WORKING_DIR
    }

    # In some cases, the Clear-Host command will not interface properly with the blocklist.
    # Clear-Host defers to whatever the 'clear' command is defined, and if that command
    # is not set up to work with Warp (or has funky other behaviors) it can cause problems.
    #
    # Specific examples:
    # - The default /usr/bin/clear on mac creates a giant, empty block to clear content
    #   off of the screen.
    # - if miniconda is installed on an osx system, the miniconda 'clear' command will be
    #   invoked for 'Clear-Host', which does not play with Warp and winds up doing nothing.

    # Because of the above, we explicitly override both 'Clear-Host' and 'clear' to
    # instead send a DCS command to Warp instructing it to clear the blocklist.
    # We are explicitly NOT calling the underlying clear implementation:
    # 1. B/c traditional clear sends an escape sequence that ends up creating an
    #    empty block that is the full height of the screen.
    # 1. B/c our other bootstrap scripts (bash, zsh, fish) do not.

    # If we ever want to call the underlying clear command, we could do so by:
    # 1. Capturing it with '$_warp_original_clear = (Get-Command Clear-Host).Definition'
    # 2. Invoking it with 'Invoke-Expression $_warp_original_clear'

    # TODO(PLAT-781): On windows, these two functions should both clear the visible screen
    # AND the scrollback
    function Clear-Host() {
        $inputBufferMsg = @{
            hook = 'Clear'
            value = @{}
        }
        Warp-Send-JsonMessage $inputBufferMsg
    }

    function clear() {
        $inputBufferMsg = @{
            hook = 'Clear'
            value = @{}
        }
        Warp-Send-JsonMessage $inputBufferMsg
    }

    function Warp-Finish-Bootstrap {
        param([decimal]$rcStartTime, [decimal]$rcEndTime)
        # This is the closest we can get in PowerShell to a proper preexec hook. We wrap the
        # invocation of PSConsoleHostReadline, and call our preexec hook before returning the
        # returned value. This allows us to preserve the any custom implementations of
        # PSConsoleHostReadLine.
        $script:oldPSConsoleHostReadLine = $function:global:PSConsoleHostReadLine
        $function:global:PSConsoleHostReadLine = {
            $line = & $script:oldPSConsoleHostReadLine

            Warp-Preexec "$line"

            $line
        }

        # This handles the case when a command is not found (ex "ehco foo"). As long as it is a
        # user-executed command, we set the $script:commandNotFound variable to $true, so we know
        # that the command failed b/c of a command lookup failure.
        $ExecutionContext.InvokeCommand.CommandNotFoundAction = {
            $commandLine = $MyInvocation.Line
            # Only trigger the preexec hook for user-submitted commands
            # $EventArgs.CommandOrigin is either 'Runspace' or 'Internal'. Internal commands are run
            # automatically by PowerShell internals. Runspace is for user-submitted/configured stuff.
            # However, Runspace still includes stuff like the prompt function, PostCommandLookupAction,
            # and the stuff we set during this bootstrap. So, add a condition to prevent preexec from
            # triggering in those cases. Note that we prefix our own functions with the "Warp-" prefix
            # so that we can ignore them here.
            if ($EventArgs.CommandOrigin -ne 'Runspace' -or ($commandLine -match '^prompt$|^Warp-')) {
                return
            }
            $script:commandNotFound = $true
        }

        # This sets up our wrapper around $function:prompt, which runs the precmd hook
        # and computes the user's custom prompt.
        $function:global:prompt = (Get-Command Warp-Prompt).ScriptBlock
        Warp-Bootstrapped -rcStartTime $rcStartTime -rcEndTime $rcEndTime
    }

    ###########################################################
    # NOTE: NO non-bootstrap / non-user calls below this line #
    ###########################################################

    # Send a precmd message to the terminal to differentiate between the warp
    # bootstrap logic pasted into the PTY and the output of shell startup files.
    Warp-Precmd -status $global:? -code $global:LASTEXITCODE

    Export-ModuleMember -Function clear, Clear-Host, Get-EpochTime, Warp-Finish-Update, Warp-Handle-DistUpgrade, Warp-Run-GeneratorCommand, Warp-Finish-Bootstrap
}

# Finally, get ready to source the user's RC files. This must be done in the global scope (not
# inside Warp-Module) in order to obey the expected scoping in PowerShell's typical startup process.
. {
    $rcStartTime = Get-EpochTime
    # Source the user's RC files
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.4#profile-types-and-locations
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.4#the-profile-variable
    foreach ($file in @($PROFILE.AllUsersAllHosts, $PROFILE.AllUsersCurrentHost, $PROFILE.CurrentUserAllHosts, $PROFILE.CurrentUserCurrentHost)) {
        if ([System.IO.File]::Exists($file)) {
            try {
                . $file
            } catch {
                Write-Host -ForegroundColor Red $_.InvocationInfo.PositionMessage
                Write-Host -ForegroundColor DarkRed $_.Exception
            }
        }
    }

    # This is a workaround for oh-my-posh's "transient prompt" feature. When enabled, it causes the
    # whole screen to clear on every command execution. It is implemented by overwriting the Enter
    # and ctrl-c key handlers. Resetting those back to default effectively disables it.
    # TODO(CORE-3234) - Find a workaround which allows transient prompt to work.
    $enterHandler = Get-PSReadLineKeyHandler | Where-Object -Property Key -EQ -Value 'Enter'
    if ($enterHandler -ne $null -and $enterHandler.Function -eq 'OhMyPoshEnterKeyHandler') {
        Set-PSReadLineKeyHandler -Chord Enter -Function AcceptLine
    }
    $ctrlcHandler = Get-PSReadLineKeyHandler | Where-Object -Property Key -EQ -Value 'Control+c'
    if ($ctrlcHandler -ne $null -and $ctrlcHandler.Function -eq 'OhMyPoshCtrlCKeyHandler') {
        Set-PSReadLineKeyHandler -Chord 'Control+c' -Function CopyOrCancelLine
    }

    $rcEndTime = Get-EpochTime

    # Capture the current prompt (potentially modified by a profile),
    # and then reset the prompt to our current noop prompt.
    $global:_warpOriginalPrompt = $function:global:prompt

    Warp-Finish-Bootstrap -rcStartTime $rcStartTime -rcEndTime $rcEndTime
    Remove-Variable -Name enterHandler, ctrlcHandler, rcStartTime, rcEndTime -Scope global -ErrorAction Ignore

    # Restore the process's original execution policy now that the user's RC files have been loaded.
    if ($global:_warp_PSProcessExecPolicy -ne $null) {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy $global:_warp_PSProcessExecPolicy
    }
}

# SIG # Begin signature block
# MII+MQYJKoZIhvcNAQcCoII+IjCCPh4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCfWM/6ROVLfaGs
# haEXfWDw7MwZm8214/bAagckdN0b9qCCIvYwggXMMIIDtKADAgECAhBUmNLR1FsZ
# lUgTecgRwIeZMA0GCSqGSIb3DQEBDAUAMHcxCzAJBgNVBAYTAlVTMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xSDBGBgNVBAMTP01pY3Jvc29mdCBJZGVu
# dGl0eSBWZXJpZmljYXRpb24gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAy
# MDAeFw0yMDA0MTYxODM2MTZaFw00NTA0MTYxODQ0NDBaMHcxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xSDBGBgNVBAMTP01pY3Jv
# c29mdCBJZGVudGl0eSBWZXJpZmljYXRpb24gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRo
# b3JpdHkgMjAyMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALORKgeD
# Bmf9np3gx8C3pOZCBH8Ppttf+9Va10Wg+3cL8IDzpm1aTXlT2KCGhFdFIMeiVPvH
# or+Kx24186IVxC9O40qFlkkN/76Z2BT2vCcH7kKbK/ULkgbk/WkTZaiRcvKYhOuD
# PQ7k13ESSCHLDe32R0m3m/nJxxe2hE//uKya13NnSYXjhr03QNAlhtTetcJtYmrV
# qXi8LW9J+eVsFBT9FMfTZRY33stuvF4pjf1imxUs1gXmuYkyM6Nix9fWUmcIxC70
# ViueC4fM7Ke0pqrrBc0ZV6U6CwQnHJFnni1iLS8evtrAIMsEGcoz+4m+mOJyoHI1
# vnnhnINv5G0Xb5DzPQCGdTiO0OBJmrvb0/gwytVXiGhNctO/bX9x2P29Da6SZEi3
# W295JrXNm5UhhNHvDzI9e1eM80UHTHzgXhgONXaLbZ7LNnSrBfjgc10yVpRnlyUK
# xjU9lJfnwUSLgP3B+PR0GeUw9gb7IVc+BhyLaxWGJ0l7gpPKWeh1R+g/OPTHU3mg
# trTiXFHvvV84wRPmeAyVWi7FQFkozA8kwOy6CXcjmTimthzax7ogttc32H83rwjj
# O3HbbnMbfZlysOSGM1l0tRYAe1BtxoYT2v3EOYI9JACaYNq6lMAFUSw0rFCZE4e7
# swWAsk0wAly4JoNdtGNz764jlU9gKL431VulAgMBAAGjVDBSMA4GA1UdDwEB/wQE
# AwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTIftJqhSobyhmYBAcnz1AQ
# T2ioojAQBgkrBgEEAYI3FQEEAwIBADANBgkqhkiG9w0BAQwFAAOCAgEAr2rd5hnn
# LZRDGU7L6VCVZKUDkQKL4jaAOxWiUsIWGbZqWl10QzD0m/9gdAmxIR6QFm3FJI9c
# Zohj9E/MffISTEAQiwGf2qnIrvKVG8+dBetJPnSgaFvlVixlHIJ+U9pW2UYXeZJF
# xBA2CFIpF8svpvJ+1Gkkih6PsHMNzBxKq7Kq7aeRYwFkIqgyuH4yKLNncy2RtNwx
# AQv3Rwqm8ddK7VZgxCwIo3tAsLx0J1KH1r6I3TeKiW5niB31yV2g/rarOoDXGpc8
# FzYiQR6sTdWD5jw4vU8w6VSp07YEwzJ2YbuwGMUrGLPAgNW3lbBeUU0i/OxYqujY
# lLSlLu2S3ucYfCFX3VVj979tzR/SpncocMfiWzpbCNJbTsgAlrPhgzavhgplXHT2
# 6ux6anSg8Evu75SjrFDyh+3XOjCDyft9V77l4/hByuVkrrOj7FjshZrM77nq81YY
# uVxzmq/FdxeDWds3GhhyVKVB0rYjdaNDmuV3fJZ5t0GNv+zcgKCf0Xd1WF81E+Al
# GmcLfc4l+gcK5GEh2NQc5QfGNpn0ltDGFf5Ozdeui53bFv0ExpK91IjmqaOqu/dk
# ODtfzAzQNb50GQOmxapMomE2gj4d8yu8l13bS3g7LfU772Aj6PXsCyM2la+YZr9T
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggcPMIIE96ADAgECAhMzAAWIsGQT
# DPJ8IRBuAAAABYiwMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDIwHhcNMjUwOTI4MTg0NDIyWhcNMjUxMDAx
# MTg0NDIyWjCBjTELMAkGA1UEBhMCVVMxETAPBgNVBAgTCE5ldyBZb3JrMREwDwYD
# VQQHEwhOZXcgWW9yazErMCkGA1UEChMiRGVudmVyIFRlY2hub2xvZ2llcywgSW5j
# LiBkYmEgV2FycDErMCkGA1UEAxMiRGVudmVyIFRlY2hub2xvZ2llcywgSW5jLiBk
# YmEgV2FycDCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBAMasNakGuDjx
# Al656EGpblQplGj8AETAAPmU1Ma2w5MKAbw2DdMNpgkhqRUluUgaDu1o+4m0dJ0D
# hCNbiz4Q/FsrCYkbU4l5o37luH35OUkPkJJ6HMbc29MLSHFf5vKcMH1joFFJh7Ec
# h1bi5Obf4vhnzyqt3evW2AGSXNuXitgmnfTEm6anCfNiwpmXINS0o4yssoHLsg16
# hUIkku05ipGh0i9yeGdHESde/b+RcFJc4uIJRN8jmQjPXtNn5WODycQy4zbicnv8
# nPSbhf9tDaMaTO4PgTup2ck/gUlBMZ5kLf7Nlf2SG8ww53OXOOyD96g9UjJ05e/0
# gvvaGzXAhSuZANlyeQJyqmi4UpRJIJYnTrCuuT/wjfZ94Duqc6aO1u1YbPMVEdkc
# UJXM5B8OceU+r7vDxAnPTBVWXSuBmCnsV0pXTjcrScVzMp7I6ugTMg8r+Ed5f01i
# f/ghuQ46q9VejxdtatbuHcIPicqCp1V1BCPCl9jAuU0hV5e2j5ZYWQIDAQABo4IC
# GDCCAhQwDAYDVR0TAQH/BAIwADAOBgNVHQ8BAf8EBAMCB4AwOwYDVR0lBDQwMgYK
# KwYBBAGCN2EBAAYIKwYBBQUHAwMGGisGAQQBgjdhgpDv2jHKof5agpXp5jTT+sAV
# MB0GA1UdDgQWBBTLbkKJMf7S8RJFqwBpnXbOnx8QiDAfBgNVHSMEGDAWgBQkRZmh
# d5AqfMPKg7BuZBaEKvgsZzBnBgNVHR8EYDBeMFygWqBYhlZodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBJRCUyMFZlcmlmaWVk
# JTIwQ1MlMjBBT0MlMjBDQSUyMDAyLmNybDCBpQYIKwYBBQUHAQEEgZgwgZUwZAYI
# KwYBBQUHMAKGWGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMv
# TWljcm9zb2Z0JTIwSUQlMjBWZXJpZmllZCUyMENTJTIwQU9DJTIwQ0ElMjAwMi5j
# cnQwLQYIKwYBBQUHMAGGIWh0dHA6Ly9vbmVvY3NwLm1pY3Jvc29mdC5jb20vb2Nz
# cDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNodHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0w
# CAYGZ4EMAQQBMA0GCSqGSIb3DQEBDAUAA4ICAQBScfMX5jTohYuUzILS/rc7blFN
# Gr9pyl9sJDFL0Vjv+X3zP48UJc7ELueuuL/qwYgBh8w5RZE9w4mr+g3Oen1/hN66
# kade/VW9EIlM8hK9/2Hs1lzF0kr4fHbLkwlfPveOL2+psZtVUz8NBbHyfsz/WFX4
# JguDwA3ffa06dQ3PRtgNuTcJbKXzK2YJiTnm+T9Z0OLUPV8bTxoxuaWN3hOeIkey
# 3TJFmStPaqnjmG0dXCyU8JwsnOm89xv1zWZWtEDi2HQpFOTZGRnPEXM7HFj9b7TY
# AAwlVGwmo0IUB5YPDKeyQYurTkHe7I2guQg7ZUG4sGzG7pzYa+ByB9v91Ms2wRdH
# bqX6clhRx1ll+6KFyOvboJdRcLoXBToL7pR06YHDK2Q0Anz9gkHEIG20/Ienp+rE
# 2qHohTyFjjHeCOxnPsxHPzm2yH8/nxOut+XMvWxFwOBqiLAIAujpz6Ajl6Tms5m9
# mMH+jyGuoPdgO19WkSs4atG9Zh/xz1NUsWHYmQQL/XEySLIk1xBCD/sLC9cfnfLG
# aPfIDq9/vUYpPtTcO/2TbSJcLdjW9/GInHVzqaUUXa2HARjbXLPqhUP6v1AbBs42
# hptTV19yPCMsppV7ImJGPtCQ2ITbwODn4uKZWQ/94MWueojs6zWe4xRSjvuJPUXb
# 8jPtCHLe1aZ+GaNCbTCCBw8wggT3oAMCAQICEzMABYiwZBMM8nwhEG4AAAAFiLAw
# DQYJKoZIhvcNAQEMBQAwWjELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjErMCkGA1UEAxMiTWljcm9zb2Z0IElEIFZlcmlmaWVkIENT
# IEFPQyBDQSAwMjAeFw0yNTA5MjgxODQ0MjJaFw0yNTEwMDExODQ0MjJaMIGNMQsw
# CQYDVQQGEwJVUzERMA8GA1UECBMITmV3IFlvcmsxETAPBgNVBAcTCE5ldyBZb3Jr
# MSswKQYDVQQKEyJEZW52ZXIgVGVjaG5vbG9naWVzLCBJbmMuIGRiYSBXYXJwMSsw
# KQYDVQQDEyJEZW52ZXIgVGVjaG5vbG9naWVzLCBJbmMuIGRiYSBXYXJwMIIBojAN
# BgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAxqw1qQa4OPECXrnoQaluVCmUaPwA
# RMAA+ZTUxrbDkwoBvDYN0w2mCSGpFSW5SBoO7Wj7ibR0nQOEI1uLPhD8WysJiRtT
# iXmjfuW4ffk5SQ+Qknocxtzb0wtIcV/m8pwwfWOgUUmHsRyHVuLk5t/i+GfPKq3d
# 69bYAZJc25eK2Cad9MSbpqcJ82LCmZcg1LSjjKyygcuyDXqFQiSS7TmKkaHSL3J4
# Z0cRJ179v5FwUlzi4glE3yOZCM9e02flY4PJxDLjNuJye/yc9JuF/20NoxpM7g+B
# O6nZyT+BSUExnmQt/s2V/ZIbzDDnc5c47IP3qD1SMnTl7/SC+9obNcCFK5kA2XJ5
# AnKqaLhSlEkglidOsK65P/CN9n3gO6pzpo7W7Vhs8xUR2RxQlczkHw5x5T6vu8PE
# Cc9MFVZdK4GYKexXSldONytJxXMynsjq6BMyDyv4R3l/TWJ/+CG5Djqr1V6PF21q
# 1u4dwg+JyoKnVXUEI8KX2MC5TSFXl7aPllhZAgMBAAGjggIYMIICFDAMBgNVHRMB
# Af8EAjAAMA4GA1UdDwEB/wQEAwIHgDA7BgNVHSUENDAyBgorBgEEAYI3YQEABggr
# BgEFBQcDAwYaKwYBBAGCN2GCkO/aMcqh/lqClenmNNP6wBUwHQYDVR0OBBYEFMtu
# Qokx/tLxEkWrAGmdds6fHxCIMB8GA1UdIwQYMBaAFCRFmaF3kCp8w8qDsG5kFoQq
# +CxnMGcGA1UdHwRgMF4wXKBaoFiGVmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2lvcHMvY3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUy
# MENBJTIwMDIuY3JsMIGlBggrBgEFBQcBAQSBmDCBlTBkBggrBgEFBQcwAoZYaHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJ
# RCUyMFZlcmlmaWVkJTIwQ1MlMjBBT0MlMjBDQSUyMDAyLmNydDAtBggrBgEFBQcw
# AYYhaHR0cDovL29uZW9jc3AubWljcm9zb2Z0LmNvbS9vY3NwMGYGA1UdIARfMF0w
# UQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTAIBgZngQwBBAEwDQYJ
# KoZIhvcNAQEMBQADggIBAFJx8xfmNOiFi5TMgtL+tztuUU0av2nKX2wkMUvRWO/5
# ffM/jxQlzsQu5664v+rBiAGHzDlFkT3Diav6Dc56fX+E3rqRp179Vb0QiUzyEr3/
# YezWXMXSSvh8dsuTCV8+944vb6mxm1VTPw0FsfJ+zP9YVfgmC4PADd99rTp1Dc9G
# 2A25NwlspfMrZgmJOeb5P1nQ4tQ9XxtPGjG5pY3eE54iR7LdMkWZK09qqeOYbR1c
# LJTwnCyc6bz3G/XNZla0QOLYdCkU5NkZGc8RczscWP1vtNgADCVUbCajQhQHlg8M
# p7JBi6tOQd7sjaC5CDtlQbiwbMbunNhr4HIH2/3UyzbBF0dupfpyWFHHWWX7ooXI
# 69ugl1FwuhcFOgvulHTpgcMrZDQCfP2CQcQgbbT8h6en6sTaoeiFPIWOMd4I7Gc+
# zEc/ObbIfz+fE6635cy9bEXA4GqIsAgC6OnPoCOXpOazmb2Ywf6PIa6g92A7X1aR
# Kzhq0b1mH/HPU1SxYdiZBAv9cTJIsiTXEEIP+wsL1x+d8sZo98gOr3+9Rik+1Nw7
# /ZNtIlwt2Nb38YicdXOppRRdrYcBGNtcs+qFQ/q/UBsGzjaGm1NXX3I8IyymlXsi
# YkY+0JDYhNvA4Ofi4plZD/3gxa56iOzrNZ7jFFKO+4k9RdvyM+0Ict7Vpn4Zo0Jt
# MIIHWjCCBUKgAwIBAgITMwAAAASWUEvS2+7LiAAAAAAABDANBgkqhkiG9w0BAQwF
# ADBjMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MTQwMgYDVQQDEytNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ29kZSBTaWduaW5nIFBD
# QSAyMDIxMB4XDTIxMDQxMzE3MzE1MloXDTI2MDQxMzE3MzE1MlowWjELMAkGA1UE
# BhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjErMCkGA1UEAxMi
# TWljcm9zb2Z0IElEIFZlcmlmaWVkIENTIEFPQyBDQSAwMjCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAOHOoOgzomOmwDsAj2wZUBdrY6N3JFGbmm+WaKzJ
# 0aeKzpsGQ4k2yKcxZGf5PJOIrwSVdcOf2/6MpCPnlwKmmsTHcgDtDKHZxFuyJ30P
# q05MpBMx8UWwjYOig7E52HP2HS+yCIiZYvJOdbqWhyy+wmJvWDXNEhWL5WhY9jtB
# 4zvcvzUZnFjY2pmTpUY8VtnFoFLFHWs0h4EQnpPO1dmzP9e2/qPFl1FvdSKYIEWr
# JomeuVhBR1ym8oZti24QSumVpkKBXhPhlqylghiv6v+EYk2jDYR11r1r/v/yOfFL
# TsVYtw2itX0OmC8iCBh8w+AprXKxor8bqav3K6x7pxjQe//0JrpdmT/R3DpmP2qb
# YFJ8E/ttIPwN+4g37rlcOskti6NP5Kf42/ifLxOBTKiIsMRgci+PNjzFQQt6nfzW
# xUGvDJo+np7FPhxKr/Wq/gG3CsLpm2aiSSpkKxmkjXVn5NjaHYHFjpqu48oW8cGT
# o5y49P28J7FDXDQHtPb/qoqM8kEHrPAN1Fz3EUG/BvnNMmjtiAon1kyu8krslCfP
# JNZrTdtgjX7W44rYgHmn6GfVZoZ+UX2/kvyuWq1b03C7pLeT3Uw0MZeeexCBOgPu
# lxQaXbIzs5C83RIexC5PD1TzI0HzwoCrSfOHNe33dgvfqcRdZREFBV2P2LQi/jZr
# PXFlAgMBAAGjggIOMIICCjAOBgNVHQ8BAf8EBAMCAYYwEAYJKwYBBAGCNxUBBAMC
# AQAwHQYDVR0OBBYEFCRFmaF3kCp8w8qDsG5kFoQq+CxnMFQGA1UdIARNMEswSQYE
# VR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBD
# AEEwEgYDVR0TAQH/BAgwBgEB/wIBADAfBgNVHSMEGDAWgBTZQSmwDw9jbO9p1/XN
# KZ6kSGow5jBwBgNVHR8EaTBnMGWgY6Bhhl9odHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBJRCUyMFZlcmlmaWVkJTIwQ29kZSUy
# MFNpZ25pbmclMjBQQ0ElMjAyMDIxLmNybDCBrgYIKwYBBQUHAQEEgaEwgZ4wbQYI
# KwYBBQUHMAKGYWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMv
# TWljcm9zb2Z0JTIwSUQlMjBWZXJpZmllZCUyMENvZGUlMjBTaWduaW5nJTIwUENB
# JTIwMjAyMS5jcnQwLQYIKwYBBQUHMAGGIWh0dHA6Ly9vbmVvY3NwLm1pY3Jvc29m
# dC5jb20vb2NzcDANBgkqhkiG9w0BAQwFAAOCAgEAZy04XZWzDSKJHSrc0mvIqPqR
# DveQnN1TsmP4ULCCHHTMpNoSTsy7fzNVl30MhJQ5P0Lci81+t03Tm+SfpzvLdKc8
# 8Iu2WLzIjairwEDudLDDiZ9094Qj6acTTYaBhVcc9lMokOG9rzq3LCyvUzhBV1m1
# DCTm0fTzNMGbAASIbuJOlVS8RA3tBknkF/2ROzx304OOC7n7eCCqmJp79QrqLKd4
# JRWLFXoC5zFmVGfFLTvRfEAogKLiWIS+TpQpLIA2/b3vx0ISxZ3pX4OnULmyBbKg
# fSJQqJ2CiWfx2jGb2LQO8vRDkSuHMZb03rQlwB2soklx9LnhP0/dsFRtHLL+VXVM
# o+sla5ttr5SmAJFyDSrwzgfPrOIfk4EoZVGtgArthVp+yc5U0m6ZNCBPERLmJpLs
# hPwU5JPd1gzMez8C55+CfuX5L2440NPDnsH6TIYfErj3UCqpmeNCOFtlMiSjDE23
# rdeiRYpkqgwoYJwgepcJaXtIH26Pe1O6a6W3wSqegdpNn+2Pk41q0GDfjnXDzskA
# HcRhjwcCUmiRt6IXZJQsYACeWpwsXmJe0o0ORLmumrYyHlYTdCnzyxT6WM+QkFPi
# Qth+/ceHfzumDhUfWmHuePwhrqe3UVCHy0r9f49Az3OhJX92MlsZaFo/MnmN5B62
# RWgJUTMIQF8j0N6xF/cwggeeMIIFhqADAgECAhMzAAAAB4ejNKN7pY4cAAAAAAAH
# MA0GCSqGSIb3DQEBDAUAMHcxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xSDBGBgNVBAMTP01pY3Jvc29mdCBJZGVudGl0eSBWZXJp
# ZmljYXRpb24gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAyMDAeFw0yMTA0
# MDEyMDA1MjBaFw0zNjA0MDEyMDE1MjBaMGMxCzAJBgNVBAYTAlVTMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xNDAyBgNVBAMTK01pY3Jvc29mdCBJRCBW
# ZXJpZmllZCBDb2RlIFNpZ25pbmcgUENBIDIwMjEwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQCy8MCvGYgo4t1UekxJbGkIVQm0Uv96SvjB6yUo92cXdylN
# 65Xy96q2YpWCiTas7QPTkGnK9QMKDXB2ygS27EAIQZyAd+M8X+dmw6SDtzSZXyGk
# xP8a8Hi6EO9Zcwh5A+wOALNQbNO+iLvpgOnEM7GGB/wm5dYnMEOguua1OFfTUITV
# MIK8faxkP/4fPdEPCXYyy8NJ1fmskNhW5HduNqPZB/NkWbB9xxMqowAeWvPgHtpz
# yD3PLGVOmRO4ka0WcsEZqyg6efk3JiV/TEX39uNVGjgbODZhzspHvKFNU2K5MYfm
# Hh4H1qObU4JKEjKGsqqA6RziybPqhvE74fEp4n1tiY9/ootdU0vPxRp4BGjQFq28
# nzawuvaCqUUF2PWxh+o5/TRCb/cHhcYU8Mr8fTiS15kRmwFFzdVPZ3+JV3s5MulI
# f3II5FXeghlAH9CvicPhhP+VaSFW3Da/azROdEm5sv+EUwhBrzqtxoYyE2wmuHKw
# s00x4GGIx7NTWznOm6x/niqVi7a/mxnnMvQq8EMse0vwX2CfqM7Le/smbRtsEeOt
# bnJBbtLfoAsC3TdAOnBbUkbUfG78VRclsE7YDDBUbgWt75lDk53yi7C3n0WkHFU4
# EZ83i83abd9nHWCqfnYa9qIHPqjOiuAgSOf4+FRcguEBXlD9mAInS7b6V0UaNwID
# AQABo4ICNTCCAjEwDgYDVR0PAQH/BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0G
# A1UdDgQWBBTZQSmwDw9jbO9p1/XNKZ6kSGow5jBUBgNVHSAETTBLMEkGBFUdIAAw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMA8G
# A1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUyH7SaoUqG8oZmAQHJ89QEE9oqKIw
# gYQGA1UdHwR9MHsweaB3oHWGc2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY3JsL01pY3Jvc29mdCUyMElkZW50aXR5JTIwVmVyaWZpY2F0aW9uJTIwUm9v
# dCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5JTIwMjAyMC5jcmwwgcMGCCsGAQUF
# BwEBBIG2MIGzMIGBBggrBgEFBQcwAoZ1aHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJZGVudGl0eSUyMFZlcmlmaWNhdGlv
# biUyMFJvb3QlMjBDZXJ0aWZpY2F0ZSUyMEF1dGhvcml0eSUyMDIwMjAuY3J0MC0G
# CCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQuY29tL29jc3AwDQYJ
# KoZIhvcNAQEMBQADggIBAH8lKp7+1Kvq3WYK21cjTLpebJDjW4ZbOX3HD5ZiG84v
# jsFXT0OB+eb+1TiJ55ns0BHluC6itMI2vnwc5wDW1ywdCq3TAmx0KWy7xulAP179
# qX6VSBNQkRXzReFyjvF2BGt6FvKFR/imR4CEESMAG8hSkPYso+GjlngM8JPn/ROU
# rTaeU/BRu/1RFESFVgK2wMz7fU4VTd8NXwGZBe/mFPZG6tWwkdmA/jLbp0kNUX7e
# lxu2+HtHo0QO5gdiKF+YTYd1BGrmNG8sTURvn09jAhIUJfYNotn7OlThtfQjXqe0
# qrimgY4Vpoq2MgDW9ESUi1o4pzC1zTgIGtdJ/IvY6nqa80jFOTg5qzAiRNdsUvzV
# koYP7bi4wLCj+ks2GftUct+fGUxXMdBUv5sdr0qFPLPB0b8vq516slCfRwaktAxK
# 1S40MCvFbbAXXpAZnU20FaAoDwqq/jwzwd8Wo2J83r7O3onQbDO9TyDStgaBNlHz
# MMQgl95nHBYMelLEHkUnVVVTUsgC0Huj09duNfMaJ9ogxhPNThgq3i8w3DAGZ61A
# MeF0C1M+mU5eucj1Ijod5O2MMPeJQ3/vKBtqGZg4eTtUHt/BPjN74SsJsyHqAdXV
# S5c+ItyKWg3Eforhox9k3WgtWTpgV4gkSiS4+A09roSdOI4vrRw+p+fL4WrxSK5n
# MYIakTCCGo0CAQEwcTBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1Mg
# QU9DIENBIDAyAhMzAAWIsGQTDPJ8IRBuAAAABYiwMA0GCWCGSAFlAwQCAQUAoF4w
# EAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwLwYJ
# KoZIhvcNAQkEMSIEIEu6zuk0h48rruXsJmrHQ7QKYMs7OxjDWdBGLLrqyvxqMA0G
# CSqGSIb3DQEBAQUABIIBgDRs7E39X+WRuBv7wIm5WjHa+u1OXZwPcEPD/m74aq50
# 1UhruprhIDECCGeK6GIoaUmHwQibx7STd7XXUVV3HyLymfLOVHHO/424uVtWpuZ5
# 4ur/d5roRNKOUCi0EqjLfAA5RgXDTxx90d2nSnz/A+CsEa1WZcVcrFimi0FZ3SP1
# Szc5duHktce6o2NL19rR9qdwN74Gzemu/zzovdKsUm/BGBeseoJLcrCzIkGybpD6
# dBuVX4qqpYlDXTjPv9YQfg5t+5B9KiEl+LDa8fIS6p6pJ7ZpNj9Acz+CT82zjIDn
# 2D51a8/JfuWmLZtzw3O09349G4Nc5N7Vld5MSBzELT0QRm6KIfVVFoGzNL3hmfeL
# y0DVUh3zQgGMZ9yUjQmJZxNtMKYE3ZXMW7e5NGJmd7rOx7uGaWWXFgcZd+UT5/GX
# CBTytAgwJSh6/4RvFLqQ1eELPMlhdV/4vMXGQ+2i242/ND/2RcYvt6OUlCcHm11A
# jo1JMhqk/ykHS4eqI+mzcKGCGBEwghgNBgorBgEEAYI3AwMBMYIX/TCCF/kGCSqG
# SIb3DQEHAqCCF+owghfmAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFiBgsqhkiG9w0B
# CRABBKCCAVEEggFNMIIBSQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFlAwQCAQUA
# BCBr8IpUn0Tgp9gUfoOMmJhNFFDLGVAyAxlJv+vwW13tuAIGaMH+bC8nGBMyMDI1
# MDkyOTAwMzMwOC40ODNaMASAAgH0oIHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBP
# cGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046N0EwMC0wNUUwLUQ5
# NDcxNTAzBgNVBAMTLE1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWUgU3RhbXBpbmcg
# QXV0aG9yaXR5oIIPITCCB4IwggVqoAMCAQICEzMAAAAF5c8P/2YuyYcAAAAAAAUw
# DQYJKoZIhvcNAQEMBQAwdzELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjFIMEYGA1UEAxM/TWljcm9zb2Z0IElkZW50aXR5IFZlcmlm
# aWNhdGlvbiBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDIwMB4XDTIwMTEx
# OTIwMzIzMVoXDTM1MTExOTIwNDIzMVowYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1Ymxp
# YyBSU0EgVGltZXN0YW1waW5nIENBIDIwMjAwggIiMA0GCSqGSIb3DQEBAQUAA4IC
# DwAwggIKAoICAQCefOdSY/3gxZ8FfWO1BiKjHB7X55cz0RMFvWVGR3eRwV1wb3+y
# q0OXDEqhUhxqoNv6iYWKjkMcLhEFxvJAeNcLAyT+XdM5i2CgGPGcb95WJLiw7HzL
# iBKrxmDj1EQB/mG5eEiRBEp7dDGzxKCnTYocDOcRr9KxqHydajmEkzXHOeRGwU+7
# qt8Md5l4bVZrXAhK+WSk5CihNQsWbzT1nRliVDwunuLkX1hyIWXIArCfrKM3+RHh
# +Sq5RZ8aYyik2r8HxT+l2hmRllBvE2Wok6IEaAJanHr24qoqFM9WLeBUSudz+qL5
# 1HwDYyIDPSQ3SeHtKog0ZubDk4hELQSxnfVYXdTGncaBnB60QrEuazvcob9n4yR6
# 5pUNBCF5qeA4QwYnilBkfnmeAjRN3LVuLr0g0FXkqfYdUmj1fFFhH8k8YBozrEaX
# nsSL3kdTD01X+4LfIWOuFzTzuoslBrBILfHNj8RfOxPgjuwNvE6YzauXi4orp4Sm
# 6tF245DaFOSYbWFK5ZgG6cUY2/bUq3g3bQAqZt65KcaewEJ3ZyNEobv35Nf6xN6F
# rA6jF9447+NHvCjeWLCQZ3M8lgeCcnnhTFtyQX3XgCoc6IRXvFOcPVrr3D9RPHCM
# S6Ckg8wggTrtIVnY8yjbvGOUsAdZbeXUIQAWMs0d3cRDv09SvwVRd61evQIDAQAB
# o4ICGzCCAhcwDgYDVR0PAQH/BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1Ud
# DgQWBBRraSg6NS9IY0DPe9ivSek+2T3bITBUBgNVHSAETTBLMEkGBFUdIAAwQTA/
# BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2Nz
# L1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcU
# AgQMHgoAUwB1AGIAQwBBMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUyH7S
# aoUqG8oZmAQHJ89QEE9oqKIwgYQGA1UdHwR9MHsweaB3oHWGc2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElkZW50aXR5JTIw
# VmVyaWZpY2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5JTIw
# MjAyMC5jcmwwgZQGCCsGAQUFBwEBBIGHMIGEMIGBBggrBgEFBQcwAoZ1aHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJZGVu
# dGl0eSUyMFZlcmlmaWNhdGlvbiUyMFJvb3QlMjBDZXJ0aWZpY2F0ZSUyMEF1dGhv
# cml0eSUyMDIwMjAuY3J0MA0GCSqGSIb3DQEBDAUAA4ICAQBfiHbHfm21WhV150x4
# aPpO4dhEmSUVpbixNDmv6TvuIHv1xIs174bNGO/ilWMm+Jx5boAXrJxagRhHQtiF
# prSjMktTliL4sKZyt2i+SXncM23gRezzsoOiBhv14YSd1Klnlkzvgs29XNjT+c8h
# IfPRe9rvVCMPiH7zPZcw5nNjthDQ+zD563I1nUJ6y59TbXWsuyUsqw7wXZoGzZwi
# jWT5oc6GvD3HDokJY401uhnj3ubBhbkR83RbfMvmzdp3he2bvIUztSOuFzRqrLfE
# vsPkVHYnvH1wtYyrt5vShiKheGpXa2AWpsod4OJyT4/y0dggWi8g/tgbhmQlZqDU
# f3UqUQsZaLdIu/XSjgoZqDjamzCPJtOLi2hBwL+KsCh0Nbwc21f5xvPSwym0Ukr4
# o5sCcMUcSy6TEP7uMV8RX0eH/4JLEpGyae6Ki8JYg5v4fsNGif1OXHJ2IWG+7zyj
# TDfkmQ1snFOTgyEX8qBpefQbF0fx6URrYiarjmBprwP6ZObwtZXJ23jK3Fg/9uqM
# 3j0P01nzVygTppBabzxPAh/hHhhls6kwo3QLJ6No803jUsZcd4JQxiYHHc+Q/wAM
# cPUnYKv/q2O444LO1+n6j01z5mggCSlRwD9faBIySAcA9S8h22hIAcRQqIGEjolC
# K9F6nK9ZyX4lhthsGHumaABdWzCCB5cwggV/oAMCAQICEzMAAABH45ULN6Fg3ccA
# AAAAAEcwDQYJKoZIhvcNAQEMBQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBS
# U0EgVGltZXN0YW1waW5nIENBIDIwMjAwHhcNMjQxMTI2MTg0ODUwWhcNMjUxMTE5
# MTg0ODUwWjCB2zELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEl
# MCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMe
# blNoaWVsZCBUU1MgRVNOOjdBMDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3Nv
# ZnQgUHVibGljIFJTQSBUaW1lIFN0YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZI
# hvcNAQEBBQADggIPADCCAgoCggIBAOhwum733P/414hmZHfYYmDZVP+N33qlguy8
# 2eB4fipfArWpWYVpdeSRVvFvV85Aky6RiRtrdYRzr1b9ngGzMC7GC5OENWVj2yTh
# liQYyDGirVnmKdQ++PhCHzFW+WGIBLo5/+4vAOxuwqWDZ8ama/O2I9I4v0/XmTTQ
# jhuyXW+WZFK63a03AlDmxemhPsYj/ZPYDQadZsUQIpELIZb2uyfL2jQs0hSXg1gB
# 3hrAZKzo4jMo+kgrUl8r3TBce9pfAYlw30/xA9Ekgcq4WhUbMhQb8LSNALitDrbJ
# Ma9zaxngDFNDB+V9UEFqIeryCf9gMelmKV4aQHYhBrNkSIRzk6vld6v2ZQNT7YUR
# 7rrDx7ZaQtdqerFoPn5lyj4T5B3BxNgajvyMXE8O82tpOvlACAhNzh1j88ELdxgX
# NyAPJTHbE5UIG+BpuonGPuteuPgGF3ZL9lNg5UeGLxwNYFp58zwmCI7wYIghG+U1
# aeDwUoW3T1l83GaxJ0ImVbDes0DCwFjXGnymaa/2vYz2s0hGRn6yHTF3ca4BJazZ
# s6uoGLRpPOBj1vcLFj7+b5FT5ROKbkmSakkz8Ag/rz9L7U3AWpcrnLFMkEgieGgS
# B0QeL5rYlHZKVXcCSklrT8HqxlqgRr7OCyEh8VrrpcGaeezJ1Xi4btbUg2ho1XDE
# EoN2ao1HAgMBAAGjggHLMIIBxzAdBgNVHQ4EFgQU5FR2WCA6Pu9PubZe8WFIRbyG
# 3WgwHwYDVR0jBBgwFoAUa2koOjUvSGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBh
# oF+gXYZbaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9z
# b2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNy
# bDB5BggrBgEFBQcBAQRtMGswaQYIKwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIw
# VGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1Ud
# JQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEG
# DCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqG
# SIb3DQEBDAUAA4ICAQANIlRD1dqYOHSCQLVe+uFXPoAzAZUq4okD62SUnMFrhRVg
# /dj2vVEtTTxFgkiM8SSnCLANaK0rnyCxnHA2Hg1zh8WJCtlQln0Eid+eh2/xY47z
# fNjxhB0kxymAHN5hVeI0J526aoUpePSYwy5ZoHKe/vDCfsWccnDMuu7iO3hUt55/
# 4HJydjA+gxrvksX/3Fmj/RMnfvWq0Fh1uxx4qY2FBRMPa8i+8+QdM8f80DYiQuxD
# UCbnWfOHnZYQPNEKhd6V3r78oKWd+wQHX+99Hqlg/HBlO9Nnu6HvLwPqDiEOkRyM
# ix6zvnhbZpGnFM+u7qf7PYTOS8cXvQH+DmgCh2ZVNQFv6nGm7vtQebROtpWh2N9c
# kk2z6HVGOcK70yKS7YqE+akGuxKd7fXLeBey2bm9y2nW0WjH1qZNa+EhXzyXUQgL
# fJf4E31wYq0vrlESX/LzKprY8hbaLXwkxEivhPuWId9fQDqx0+yXsa50vIRUcBax
# bw0VXO3+93JGHMxSmzGE8vWoZCAPjlD7duBOV6XkxaVaBgb5v4stRdHm6LJtsizC
# c5FNT+MPJw0DHy7hzn7Xix6fn9+apytBrfXqXtapxDqs5yjEMXKbuTZFW4SFk1Dh
# c1cIojuRvw8ytG0xuhtXSavJ3RSVtBRs+wm432dQTYAOaCc7dtAbIRG+ml50ITGC
# B0Mwggc/AgEBMHgwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0
# YW1waW5nIENBIDIwMjACEzMAAABH45ULN6Fg3ccAAAAAAEcwDQYJYIZIAWUDBAIB
# BQCgggScMBEGCyqGSIb3DQEJEAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcN
# AQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTI1MDkyOTAwMzMwOFowLwYJKoZIhvcNAQkE
# MSIEIMxOR+7KWDVAalIti6Ny5riNwzV+KiI6IW7vRMl2c9G8MIG5BgsqhkiG9w0B
# CRACLzGBqTCBpjCBozCBoAQgk2bzlnKFAAYZ71A+F3f7G+YwoK9+MeF/y2XqZEgK
# zKcwfDBlpGMwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1w
# aW5nIENBIDIwMjACEzMAAABH45ULN6Fg3ccAAAAAAEcwggNeBgsqhkiG9w0BCRAC
# EjGCA00wggNJoYIDRTCCA0EwggIpAgEBMIIBCaGB4aSB3jCB2zELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFt
# ZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjdBMDAt
# MDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lIFN0
# YW1waW5nIEF1dGhvcml0eaIjCgEBMAcGBSsOAwIaAxUAIAXT2b4gvIw3J1lPs/eU
# 4s1UXN2gZzBlpGMwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0
# YW1waW5nIENBIDIwMjAwDQYJKoZIhvcNAQELBQACBQDshDfeMCIYDzIwMjUwOTI4
# MjI0MDMwWhgPMjAyNTA5MjkyMjQwMzBaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIF
# AOyEN94CAQAwBwIBAAICBqUwBwIBAAICD9IwCgIFAOyFiV4CAQAwNgYKKwYBBAGE
# WQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDAN
# BgkqhkiG9w0BAQsFAAOCAQEAVde9EL1n62zXYeI4r7ghzcd6LP8GDWSJaPGDTXlc
# ASqCWvc9j0ugAAs3GydmdMk5bsVCDpq4kCFuwGyEFX2qouoVMa4tHSl0/qKq5KhD
# NTdN+zKt7/zdYcnARGDjuCaUX2ZnZNlxKYxZ8dxnAyn3kZUGrmZ0uTfG9FIaNfwb
# oOQonU6hRHJ/JrEYG8VaHXh5LPltAE/Rqbn05XIrF6G2+XkOi6khHQTeVQKpgDYa
# vhsEcTynKiniHbVr0KPiLI202Y9A6zzil+cHMkRsXkXsvZHc20coAI+PQBIVNqx+
# ODYCzpss4hVezOq/FzvHYolmM+Xy6hRkC3i1ExTySJuvYjANBgkqhkiG9w0BAQEF
# AASCAgAY3vg44LkPrB1M1eY/xewnls0a/mCJo06sg2es1RO/W1fD+fCdu1h8kiG2
# wxZjOd2onE+yqoY+mx0/zD4uBG62S3JdJz3YfgSJjRyHgt0u3EtfajuUC3eR0BnU
# Ar8029Dq6LfoTD2/K2CEntBKgmLUmh1i8bDN6mlxTrcw64oRdP+UzLAjjQwbLd/y
# orkJFaFgjjISe1kyVDdSeH9E+g2gbaKWjB2EdvAU9+Af7Hc0aCzYEdnkanWQSLIK
# YEA6f+oO1vMbmkkeeFrR8aX8FEwfYDaGfJY+DC9V38Bvd9kXNFAQfp6kkLLVJygC
# zqUIRRz903M7rGGrGz4AIOQbT0+xVITHatjmJtmXjQW/LUlqFkYuaBWC00/g8+dB
# C7c/lgR1UGB7HfABtNhJ08hotB49yagndMzqy9RuwEph83PqtZfHU7oWVIuBncxi
# 6wC4hWSuwSsSWxtRyec9q25hAaVHHuK+5rNfkifteI9/FcrIbHESq2swRFeA9+N3
# kANuZ8hER7nGJGgGcl9Ti2EMekw9lDYv/z4KvUYs+grUZrOo6uf3bC6V5kD8v+CD
# wGSGTRFbgLxg7c40hJoxsil489YPBopl8Zzkka5ka1L6TOXe/aY8RT7ziaJNyXg9
# hj8BC0VsSVj0R0mw1NnD7nMe2L42IvRAWvkvryatKN2tXhN8ow==
# SIG # End signature block
