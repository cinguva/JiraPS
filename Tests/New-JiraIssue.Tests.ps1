﻿Describe "New-JiraIssue" {

    Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop

    InModuleScope JiraPS {

        . "$PSScriptRoot/Shared.ps1"


        $jiraServer = 'https://jira.example.com'

        Mock Get-JiraConfigServer {
            $jiraServer
        }

        # If we don't override this in a context or test, we don't want it to
        # actually try to query a JIRA instance
        Mock Invoke-JiraMethod {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            @{ Key = "TEST-01"}
        }

        Mock Get-JiraIssue {
            [PSCustomObject] @{ Key = "TEST-01"}
        }

        Mock Get-JiraProject {
            $object = [PSCustomObject] @{
                'ID'  = $Project
                'Key' = "TEST"
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
            return $object
        }

        Mock Get-JiraIssueType {
            $object = [PSCustomObject] @{
                'ID' = $IssueType;
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.IssueType')
            return $object
        }

        Mock Get-JiraUser {
            $object = [PSCustomObject] @{
                'Name' = $UserName;
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
            return $object
        }

        # This one needs to be able to output multiple objects
        Mock Get-JiraField {
            $Field | % {
                $object = [PSCustomObject] @{
                    'Id' = $_
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Field')
                $object
            }
        }

        Mock Get-JiraIssueCreateMetadata {
            @(
                @{Name = 'Project'; ID = 'Project'; Required = $true}
                @{Name = 'IssueType'; ID = 'IssueType'; Required = $true}
                @{Name = 'Priority'; ID = 'Priority'; Required = $true}
                @{Name = 'Summary'; ID = 'Summary'; Required = $true}
                @{Name = 'Description'; ID = 'Description'; Required = $true}
                @{Name = 'Reporter'; ID = 'Reporter'; Required = $true}
            )
        }

        $newParams = @{
            'Project'     = 'TEST';
            'IssueType'   = 1;
            'Priority'    = 1;
            'Reporter'    = 'testUsername';
            'Summary'     = 'Test summary';
            'Description' = 'Test description';
        }

        Context "Sanity checking" {
            $command = Get-Command -Name New-JiraIssue

            defParam $command 'Project'
            defParam $command 'IssueType'
            defParam $command 'Priority'
            defParam $command 'Summary'
            defParam $command 'Description'
            defParam $command 'Reporter'
            defParam $command 'Labels'
            defParam $command 'Fields'
            defParam $command 'Credential'
        }

        Context "Behavior testing" {
            It "Creates an issue in JIRA" {
                { New-JiraIssue @newParams } | Should Not Throw
                # The String in the ParameterFilter is made from the keywords
                # we should expect to see in the JSON that should be sent,
                # including the summary provided in the test call above.
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/*/issue" }
            }
        }

        Context "Input testing" {
            It "Checks to make sure all required fields are provided" {
                # We'll create a custom field that's required, then see what happens when we don't provide it
                Mock Get-JiraIssueCreateMetadata {
                    @(
                        @{Name = 'Project'; ID = 'Project'; Required = $true}
                        @{Name = 'IssueType'; ID = 'IssueType'; Required = $true}
                        @{Name = 'Priority'; ID = 'Priority'; Required = $true}
                        @{Name = 'Summary'; ID = 'Summary'; Required = $true}
                        @{Name = 'Description'; ID = 'Description'; Required = $true}
                        @{Name = 'Reporter'; ID = 'Reporter'; Required = $true}
                        @{Name = 'CustomField'; ID = 'CustomField'; Required = $true}
                    )
                }

                { New-JiraIssue @newParams } | Should Throw
                { New-JiraIssue @newParams -Fields @{'CustomField' = '.'} } | Should Not Throw
            }
        }
    }
}
