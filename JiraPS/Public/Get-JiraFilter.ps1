﻿function Get-JiraFilter {
    <#
    .Synopsis
       Returns information about a filter in JIRA
    .DESCRIPTION
       This function returns information about a filter in JIRA, including the JQL syntax of the filter, its owner, and sharing status.

       This function is only capable of returning filters by their Filter ID. This is a limitation of JIRA's REST API.  The easiest way to obtain the ID of a filter is to load the filter in the "regular" Web view of JIRA, then copy the ID from the URL of the page.
    .EXAMPLE
       Get-JiraFilter -Id 12345
       Gets a reference to filter ID 12345 from JIRA
    .EXAMPLE
        $filterObject | Get-JiraFilter
        Gets the information of a filter by providing a filter object
    .INPUTS
       [Object[]] The filter to look up in JIRA. This can be a String (filter ID) or a JiraPS.Filter object.
    .OUTPUTS
       [JiraPS.Filter[]] Filter objects
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByFilterID')]
    param(
        # ID of the filter to search for.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'ByFilterID'
        )]
        [String[]] $Id,

        # Object of the filter to search for.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'ByInputObject',
            ValueFromPipelineByPropertyName = $true
        )]
        [Object[]] $InputObject,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/filter/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            "ByFilterID" {
                foreach ($_id in $Id) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing filterId [${_id}]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing filterId [${_id}]"

                    $parameter = @{
                        URI        = $resourceURi -f $_id
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraFilter -InputObject $result)
                }
            }
            "ByInputObject" {
                foreach ($object in $InputObject) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing InputObject [${object}]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing InputObject [${object}]"

                    if ((Get-Member -InputObject $object).TypeName -eq 'JiraPS.Filter') {
                        $thisId = $object.ID
                    }
                    else {
                        $thisId = $object.ToString()
                        Write-Verbose "[$($MyInvocation.MyCommand.Name)] ID is assumed to be [$thisId] via ToString()"
                    }

                    Write-Output (Get-JiraFilter -Id $thisId -Credential $Credential)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
