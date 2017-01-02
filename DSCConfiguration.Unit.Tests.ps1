    $Name = Get-Item -Path $env:APPVEYOR_BUILD_FOLDER | ForEach-Object -Process {$_.Name}
    $Files = Get-ChildItem -Path $env:APPVEYOR_BUILD_FOLDER
    $Manifest = Import-PowerShellDataFile -Path "$env:APPVEYOR_BUILD_FOLDER\$Name.psd1"
    
<#
    PSSA = PS Script Analyzer
    Only the first and last tests here will pass/fail correctly at the moment. The other 3 tests
    will currently always pass, but print warnings based on the problems they find.
    These automatic passes are here to give contributors time to fix the PSSA
    problems before we turn on these tests. These 'automatic passes' should be removed
    along with the first test (which is replaced by the following 3) around Jan-Feb
    2017.
#>
Describe 'Common Tests - PS Script Analyzer' {

    $requiredPssaRuleNames = @(
        'PSAvoidDefaultValueForMandatoryParameter',
        'PSAvoidDefaultValueSwitchParameter',
        'PSAvoidInvokingEmptyMembers',
        'PSAvoidNullOrEmptyHelpMessageAttribute',
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingComputerNameHardcoded',
        'PSAvoidUsingDeprecatedManifestFields',
        'PSAvoidUsingEmptyCatchBlock',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPositionalParameters',
        'PSAvoidShouldContinueWithoutForce',
        'PSAvoidUsingWMICmdlet',
        'PSAvoidUsingWriteHost',
        'PSDSCReturnCorrectTypesForDSCFunctions',
        'PSDSCUseIdenticalMandatoryParametersForDSC',
        'PSDSCUseIdenticalParametersForDSC',
        'PSMissingModuleManifestField',
        'PSPossibleIncorrectComparisonWithNull',
        'PSProvideCommentHelp',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSUseApprovedVerbs',
        'PSUseCmdletCorrectly',
        'PSUseOutputTypeCorrectly'
    )

    $flaggedPssaRuleNames = @(
        'PSAvoidGlobalVars',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingUsernameAndPasswordParams',
        'PSShouldProcess',
        'PSUseDeclaredVarsMoreThanAssigments',
        'PSUsePSCredentialType'
    )

    $ignorePssaRuleNames = @(
        'PSDSCDscExamplesPresent',
        'PSDSCDscTestsPresent',
        'PSUseBOMForUnicodeEncodedFile',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseSingularNouns',
        'PSUseToExportFieldsInManifest',
        'PSUseUTF8EncodingForHelpFile'
    )

    $Psm1Files = Get-Psm1FileList -FilePath $Files

    foreach ($Psm1File in $Psm1Files)
    {
        $invokeScriptAnalyzerParameters = @{
            Path = $Psm1File.FullName
            ErrorAction = 'SilentlyContinue'
            Recurse = $true
        }

        Context $Psm1File.Name {
            It 'Should pass all error-level PS Script Analyzer rules' {
                $errorPssaRulesOutput = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters -Severity 'Error'

                if ($null -ne $errorPssaRulesOutput) {
                    Write-Warning -Message 'Error-level PSSA rule(s) did not pass.'
                    Write-Warning -Message 'The following PSScriptAnalyzer errors need to be fixed:'

                    foreach ($errorPssaRuleOutput in $errorPssaRulesOutput)
                    {
                        Write-Warning -Message "$($errorPssaRuleOutput.ScriptName) (Line $($errorPssaRuleOutput.Line)): $($errorPssaRuleOutput.Message)"
                    }

                    Write-Warning -Message  'For instructions on how to run PSScriptAnalyzer on your own machine, please go to https://github.com/powershell/PSScriptAnalyzer'
                }

                $errorPssaRulesOutput | Should Be $null
            }

            It 'Should pass all required PS Script Analyzer rules' {
                $requiredPssaRulesOutput = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters -IncludeRule $requiredPssaRuleNames

                if ($null -ne $requiredPssaRulesOutput) {
                    Write-Warning -Message 'Required PSSA rule(s) did not pass.'
                    Write-Warning -Message 'The following PSScriptAnalyzer errors need to be fixed:'

                    foreach ($requiredPssaRuleOutput in $requiredPssaRulesOutput)
                    {
                        Write-Warning -Message "$($requiredPssaRuleOutput.ScriptName) (Line $($requiredPssaRuleOutput.Line)): $($requiredPssaRuleOutput.Message)"
                    }

                    Write-Warning -Message  'For instructions on how to run PSScriptAnalyzer on your own machine, please go to https://github.com/powershell/PSScriptAnalyzer'
                }

                <#
                    Automatically passing this test since it may break several modules at the moment.
                    Automatic pass to be removed Jan-Feb 2017.
                #>
                $requiredPssaRulesOutput = $null
                $requiredPssaRulesOutput | Should Be $null
            }

            It 'Should pass all flagged PS Script Analyzer rules' {
                $flaggedPssaRulesOutput = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters -IncludeRule $flaggedPssaRuleNames

                if ($null -ne $flaggedPssaRulesOutput) {
                    Write-Warning -Message 'Flagged PSSA rule(s) did not pass.'
                    Write-Warning -Message 'The following PSScriptAnalyzer errors need to be fixed or approved to be suppressed:'

                    foreach ($flaggedPssaRuleOutput in $flaggedPssaRulesOutput)
                    {
                        Write-Warning -Message "$($flaggedPssaRuleOutput.ScriptName) (Line $($flaggedPssaRuleOutput.Line)): $($flaggedPssaRuleOutput.Message)"
                    }

                    Write-Warning -Message  'For instructions on how to run PSScriptAnalyzer on your own machine, please go to https://github.com/powershell/PSScriptAnalyzer'
                }

                <#
                    Automatically passing this test since it may break several modules at the moment.
                    Automatic pass to be removed Jan-Feb 2017.
                #>
                $flaggedPssaRulesOutput = $null
                $flaggedPssaRulesOutput | Should Be $null
            }

            It 'Should pass any recently-added, error-level PS Script Analyzer rules' {
                $knownPssaRuleNames = $requiredPssaRuleNames + $flaggedPssaRuleNames + $ignorePssaRuleNames

                $newErrorPssaRulesOutput = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters -ExcludeRule $knownPssaRuleNames -Severity 'Error'

                if ($null -ne $newErrorPssaRulesOutput) {
                    Write-Warning -Message 'Recently-added, error-level PSSA rule(s) did not pass.'
                    Write-Warning -Message 'The following PSScriptAnalyzer errors need to be fixed or approved to be suppressed:'

                    foreach ($newErrorPssaRuleOutput in $newErrorPssaRulesOutput)
                    {
                        Write-Warning -Message "$($newErrorPssaRuleOutput.ScriptName) (Line $($newErrorPssaRuleOutput.Line)): $($newErrorPssaRuleOutput.Message)"
                    }

                    Write-Warning -Message  'For instructions on how to run PSScriptAnalyzer on your own machine, please go to https://github.com/powershell/PSScriptAnalyzer'
                }

                <#
                    Automatically passing this test since it may break several modules at the moment.
                    Automatic pass to be removed Jan-Feb 2017.
                #>
                $newErrorPssaRulesOutput = $null
                $newErrorPssaRulesOutput | Should Be $null
            }

            It 'Should not suppress any required PS Script Analyzer rules' {
                $requiredRuleIsSuppressed = $false

                $suppressedRuleNames = Get-SuppressedPSSARuleNameList -FilePath $Psm1File.FullName

                foreach ($suppressedRuleName in $suppressedRuleNames)
                {
                    $suppressedRuleNameNoQuotes = $suppressedRuleName.Replace("'", '')

                    if ($requiredPssaRuleNames -icontains $suppressedRuleNameNoQuotes)
                    {
                        Write-Warning -Message "The file $($Psm1File.Name) contains a suppression of the required PS Script Analyser rule $suppressedRuleNameNoQuotes. Please remove the rule suppression."
                        $requiredRuleIsSuppressed = $true
                    }
                }

                $requiredRuleIsSuppressed | Should Be $false
            }
        }
    }
}

Describe 'Common Tests - File Parsing' {
    $psm1Files = Get-Psm1FileList -FilePath $Files

    foreach ($psm1File in $psm1Files)
    {
        Context $psm1File.Name {   
            It 'Should not contain parse errors' {
                $containsParseErrors = $false

                $parseErrors = Get-FileParseErrors -FilePath $psm1File.FullName

                if ($null -ne $parseErrors)
                {
                    Write-Warning -Message "There are parse errors in $($psm1File.FullName):"
                    Write-Warning -Message ($parseErrors | Format-List | Out-String)

                    $containsParseErrors = $true
                }

                $containsParseErrors | Should Be $false
            }
        }
    }
}

Describe 'Common Tests - File Formatting' {
    $textFiles = Get-TextFilesList $Files
    
    It "Should not contain any files with Unicode file encoding" {
        $containsUnicodeFile = $false

        foreach ($textFile in $textFiles)
        {
            if (Test-FileInUnicode $textFile) {
                if($textFile.Extension -ieq '.mof')
                {
                    Write-Warning -Message "File $($textFile.FullName) should be converted to ASCII. Use fixer function 'Get-UnicodeFilesList `$pwd | ConvertTo-ASCII'."
                }
                else
                {
                    Write-Warning -Message "File $($textFile.FullName) should be converted to UTF-8. Use fixer function 'Get-UnicodeFilesList `$pwd | ConvertTo-UTF8'."
                }

                $containsUnicodeFile = $true
            }
        }

        $containsUnicodeFile | Should Be $false
    }

    It 'Should not contain any files with tab characters' {
        $containsFileWithTab = $false

        foreach ($textFile in $textFiles)
        {
            $fileName = $textFile.FullName
            $fileContent = Get-Content -Path $fileName -Raw

            $tabCharacterMatches = $fileContent | Select-String "`t"

            if ($null -ne $tabCharacterMatches)
            {
                Write-Warning -Message "Found tab character(s) in $fileName. Use fixer function 'Get-TextFilesList `$pwd | ConvertTo-SpaceIndentation'."
                $containsFileWithTab = $true
            }
        }

        $containsFileWithTab | Should Be $false
    }

    It 'Should not contain empty files' {
        $containsEmptyFile = $false

        foreach ($textFile in $textFiles)
        {
            $fileContent = Get-Content -Path $textFile.FullName -Raw

            if([String]::IsNullOrWhiteSpace($fileContent))
            {
                Write-Warning -Message "File $($textFile.FullName) is empty. Please remove this file."
                $containsEmptyFile = $true
            }
        }

        $containsEmptyFile | Should Be $false
    }

    It 'Should not contain files without a newline at the end' {
        $containsFileWithoutNewLine = $false

        foreach ($textFile in $textFiles)
        {
            $fileContent = Get-Content -Path $textFile.FullName -Raw

            if(-not [String]::IsNullOrWhiteSpace($fileContent) -and $fileContent[-1] -ne "`n")
            {
                if (-not $containsFileWithoutNewLine)
                {
                    Write-Warning -Message 'Each file must end with a new line.'
                }

                Write-Warning -Message "$($textFile.FullName) does not end with a new line. Use fixer function 'Add-NewLine'"
                
                $containsFileWithoutNewLine = $true
            }
        }

                
        $containsFileWithoutNewLine | Should Be $false
    }
}

<#
#>
Describe 'Common Tests - Configuration Module Requirements' {
    Context "$Name module manifest properties" {
        It 'Contains a module file that aligns to the folder name' {
            $Files.Name.Contains("$Name.psm1") | Should Be True
        }
        It 'Contains a module manifest that aligns to the folder and module names' {
            $Files.Name.Contains("$Name.psd1") | Should Be True
        }
        It 'Contains a readme' {
            $Files.Name.Contains("README.md") | Should Be True
        }
        It "Manifest $env:APPVEYOR_BUILD_FOLDER\$Name.psd1 should import as a data file" {
            $Manifest.GetType() | Should Be 'Hashtable'
        }
        It 'Should point to the root module in the manifest' {
            $Manifest.RootModule | Should Be ".\$Name.psm1"
        }
        It 'Should have a GUID in the manifest' {
            $Manifest.GUID | Should Match '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}'
        }
        It 'Should list requirements in the manifest' {
            $Manifest.RequiredModules | Should Not Be Null
        }
        It 'Should list a module version in the manifest' {
            $Manifest.ModuleVersion | Should BeGreaterThan 0.0.0.0
        }
        It 'Should list an author in the manifest' {
            $Manifest.Author | Should Not Be Null
        }
        It 'Should provide a description in the manifest' {
            $Manifest.Description | Should Not Be Null
        }
        It 'Should require PowerShell version 4 or later in the manifest' {
            $Manifest.PowerShellVersion | Should BeGreaterThan 4.0
        }
        It 'Should require CLR version 4 or later in the manifest' {
            $Manifest.CLRVersion | Should BeGreaterThan 4.0
        }
        It 'Should export functions in the manifest' {
            $Manifest.FunctionsToExport | Should Not Be Null
        }
        It 'Should include tags in the manifest' {
            $Manifest.PrivateData.PSData.Tags | Should Not Be Null
        }
        It 'Should include a project URI in the manifest' {
            $Manifest.PrivateData.PSData.ProjectURI | Should Not Be Null
        }
    }
    Context "$Name required modules" {
        ForEach ($RequiredModule in $Manifest.RequiredModules[0]) {
            if ($RequiredModule.GetType().Name -eq 'Hashtable') {
                It "$($RequiredModule.ModuleName) version $($RequiredModule.ModuleVersion) should be found in the PowerShell public gallery" {
                    {Find-Module -Name $RequiredModule.ModuleName -RequiredVersion $RequiredModule.ModuleVersion} | Should Not Be Null
                }
                It "$($RequiredModule.ModuleName) version $($RequiredModule.ModuleVersion) should install locally without error" {
                    {Install-Module -Name $RequiredModule.ModuleName -RequiredVersion $RequiredModule.ModuleVersion -Force} | Should Not Throw
                } 
            }
            else {
                It "$RequiredModule should be found in the PowerShell public gallery" {
                    {Find-Module -Name $RequiredModule} | Should Not Be Null
                }
                It "$RequiredModule should install locally without error" {
                    {Install-Module -Name $RequiredModule -Force} | Should Not Throw
                }
            }
        }
    }
    Context "$Name configurations" {
        It "$Name imports as a module" {
            {Import-Module -Name $Name} | Should Not Throw
        }
        It "$Name should provide configurations" {
            $Configurations = Get-Command -Type Configuration -Module $Name
            $Configurations | Should Not Be Null
        }
        ForEach ($Configuration in $Configurations) {
            It "$($Configuration.Name) should compile without error" {
                {Invoke-Expression "$($Configuration.Name) -Out c:\dsc\$($Configuration.Name)"} | Should Not Throw
            }
            It "$($Configuration.Name) should produce a mof file" {
                Get-ChildItem -Path "c:\dsc\$($Configuration.Name)\*.mof" | Should Not Be Null
            }
        }
    }
}

# after:
# technically are these unit or integration?

# modules should be in AADSC

# modules should show extracted activities

# configurations should be in AADSC

# configurations should show as compiled
