<#
.SYNOPSIS
    Diagnoses Azure Synapse Studio connectivity issues.
    Revision b297783237cb12eb468ec887ae68be67d4eaeab8 (2021-05-14 13:36:52Z)
.DESCRIPTION
    This script helps to diagnoses connecitivity issue preventing user accessing
    Azure Synpase Studio or its functionality.

    This script assumes the endpoints used by Azure Synapse Studio is up and working.

    System Requirement:
        PowerShell 5 or PowerShell Core 6+ on Windows
        PowerShell Core on Linux is supported
.EXAMPLE

    PS> ./Test-AzureSynapse.ps1

    # You will be prompted for your Azure Synapse Workspace name.

.EXAMPLE

    PS> ./Test-AzureSynapse.ps1 myworkspacename
#>

#Requires -Version 5.0

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Enter your Synapse Workspace name.")]
    [ValidateLength(1, 1024)]
    [ValidatePattern("[\w-_]+")]
    [string]
    $Workspace,
    [Parameter()]
    [string]
    $OutputPath = "*"
)

$ErrorActionPreference = "Stop"

if ($OutputPath -eq '*') {
    $OutputPath = 'TestAzureSynapse_{0:yyyyMmddHHmmss}.log' -f (Get-Date)
}

if ($OutputPath) {
    "`nTest-AzureSynapse" >> $OutputPath
    Get-Date -Format u >> $OutputPath
    "Workspace: $Workspace" >> $OutputPath
    "----------" >> $OutputPath
    "" >> $OutputPath
    "PSVersionTable" >> $OutputPath
    $PSVersionTable >> $OutputPath
    'Revision: b297783237cb12eb468ec887ae68be67d4eaeab8' >> $OutputPath
    'Timestamp: 2021-05-14 13:36:52Z' >> $OutputPath

    $OutputPath = (Resolve-Path $OutputPath).Path
    Write-Host "Write diagostic logs to: $OutputPath"
}

$THttpRequestException = ([System.Management.Automation.PSTypeName]"System.Net.Http.HttpRequestException").Type

class UrlTestResponse {
    [int]$StatusCode
    $Headers
    [string]$Content
}

class UrlTestResult {
    [DateTime]$Time
    [string]$Url
    [string]$Method
    [bool]$Authorization = $False
    [bool]$Passed = $False
    [bool]$Reachable = $False
    [string]$CorsOrigin = $Null
    [object]$WebResponseStatus = $Null
    [double]$DurationMS = $Null
    [Exception]$Exception = $Null
    [string]$BodySnippet = $Null
    # Content length in characters.
    [int]$BodyLength = $Null
}

function Test-Url {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Method,
        [Parameter()]
        [string]
        $Url,
        [Parameter()]
        [scriptblock]
        $ResponseAssertions,
        [Parameter()]
        [string]
        $CorsMethod,
        # Send request with dummy Authorization header
        [Parameter()]
        [switch]
        $Authorization
    )
    Write-Host "  $Method $Url"
    $Headers = @{
        "X-Requested-By" = "Test-SynapseConnectivity"
        "Origin"         = "https://web.azuresynapse.net"
    }
    if ($CorsMethod) {
        $Headers["Access-Control-Request-Method"] = $CorsMethod;
    }
    if ($Authorization) {
        # {"typ":"JWT","alg":"RS256"}
        $Headers["Authorization"] = "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9"
    }
    $Result = [UrlTestResult]::new()
    $Result.Time = Get-Date
    $Result.Url = $Url
    $Result.Method = $Method
    $Result.Authorization = $Authorization
    $TimeoutSec = 30
    try {
        Write-Host ("    {0:u}" -f ($Result.Time)) -NoNewline
        $Response = $null
        $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            try {
                $r = if ((Get-Command Invoke-WebRequest).Parameters.SkipHttpErrorCheck) {
                    # PowerShell 7+
                    Invoke-WebRequest $Url -Method $Method -Headers $Headers -UseBasicParsing -TimeoutSec $TimeoutSec -SkipHttpErrorCheck
                }
                else {
                    Invoke-WebRequest $Url -Method $Method -Headers $Headers -UseBasicParsing -TimeoutSec $TimeoutSec
                }
                $Response = [UrlTestResponse]::new()
                $Response.StatusCode = $r.StatusCode
                $Response.Headers = $r.Headers
                $Response.Content = $r.Content
            }
            finally {
                $Stopwatch.Stop()
                $Result.DurationMS = $Stopwatch.Elapsed.TotalMilliseconds
                Write-Host ("  {0:0.000}s" -f $Stopwatch.Elapsed.TotalSeconds) -NoNewline
            }
        }
        catch [System.OperationCanceledException] {
            $Response = $null
            Write-Host ("  Timeout" -f $TimeoutSec) -ForegroundColor Yellow -NoNewline
            $Result.WebResponseStatus = "Timeout"
            throw
        }
        catch [System.Net.WebException] {
            # PS 5-
            if ($_.Exception.Status -eq "ProtocolError") {
                $Response = [UrlTestResponse]::new()
                $Response.StatusCode = $_.Exception.Response.StatusCode
                $Response.Headers = $_.Exception.Response.Headers
                $Response.Content = if ($_.ErrorDetails.Message) {
                    $_.ErrorDetails.Message
                }
                else {
                    # $_.ErrorDetails.Message does not work for SQL...
                    [System.IO.Stream] $ContentStream = $_.Exception.Response.GetResponseStream()
                    try {
                        $reader = [System.IO.StreamReader] $ContentStream
                        $reader.ReadToEnd()
                        $reader.Close()
                    }
                    finally {
                        $ContentStream.Close()
                    }
                }
            }
            else {
                Write-Host "  $($_.Exception.Status)" -ForegroundColor Yellow -NoNewline
                $Result.WebResponseStatus = $_.Exception.Status
                throw
            }
        }
        catch [System.Exception] {
            if ($THttpRequestException -and $THttpRequestException.IsInstanceOfType($_.Exception)) {
                # PS 6+
                if ($_.Exception.Response) {
                    # Microsoft.PowerShell.Commands.HttpResponseException
                    $Response = [UrlTestResponse]::new()
                    $Response.StatusCode = $_.Exception.Response.StatusCode
                    $Response.Headers = $_.Exception.Response.Headers
                    $Response.Content = $_.ErrorDetails.Message
                }
                else {
                    Write-Host "  $($_.Exception.InnerException.SocketErrorCode)" -ForegroundColor Yellow -NoNewline
                    $Result.WebResponseStatus = $_.Exception.InnerException.SocketErrorCode
                    throw
                }
            }
        }
        $Result.BodyLength = if ($Response.Content) { $Response.Content.Length } else { 0 }
        $Result.BodySnippet = if ($Response.Content) {
            if ($Response.Content.Length -gt 1024) { $Response.Content.Substring(0, 1024) } else { $Response.Content }
        }
        Write-Host "  HTTP $([int]$Response.StatusCode)" -NoNewline
        Write-Host "  $($Result.BodyLength) chars" -NoNewline
        $Result.Reachable = [bool]$Response
        $CORSOrigin = if ($Response.Headers.TryGetValues) {
            $x = $Null
            # System.Net.Http.Headers.HttpHeaders
            if ($Response.Headers.TryGetValues("Access-Control-Allow-Origin", [ref] $x)) { $x }
        }
        else {
            # System.Net.WebHeaderCollection
            $Response.Headers["Access-Control-Allow-Origin"]
        }
        $Result.CorsOrigin = $CORSOrigin
        if ($CORSOrigin -contains "https://web.azuresynapse.net") {
            Write-Host "  CORS" -NoNewline
        }
        elseif ($CORSOrigin -contains "*") {
            Write-Host "  CORS(*)" -NoNewline
        }
        elseif ($CORSOrigin) {
            Write-Host "  CORS($CORSOrigin)" -ForegroundColor Yellow -NoNewline
        }
        if ($ResponseAssertions) {
            @($Response) | % $ResponseAssertions
            Write-Host "  Passed" -ForegroundColor Green -NoNewline
        }
        $Result.Passed = $True
        Write-Host
    }
    catch {
        Write-Host "  Failed  " -ForegroundColor Red -NoNewline
        Write-Host $_ -ForegroundColor Red
        $ex = $_.Exception
        $Result.Exception = $ex
        while ($ex) {
            Write-Host "    --> $($ex.GetType()): $($ex.Message)" -ForegroundColor Red
            $ex = $ex.InnerException
        }
    }
    return $Result
}

function CheckStatusCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Response,
        [Parameter(Mandatory = $true)]
        [int[]]
        $ExpectedStatus
    )
    if ($Response.StatusCode -notin $ExpectedStatus) {
        throw "Unexpected status code: $([int]$_.StatusCode). Expecting: $ExpectedStatus."
    }
}

function Test-ArmErrorCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Response,
        [Parameter(Mandatory = $true)]
        [string]
        $ExpectedErrorCode
    )

    $json = $Response.Content | ConvertFrom-Json
    $errorCode = $json.error.code
    $errorMessage = $json.error.message
    if ($errorCode -ne $ExpectedErrorCode) {
        throw "Unexpected ARM error code: $errorCode ($errorMessage). Expecting: $ExpectedErrorCode."
    }
}

function Test-RpErrorCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Response,
        [Parameter(Mandatory = $true)]
        [string]
        $ExpectedErrorCode
    )

    $json = $Response.Content | ConvertFrom-Json
    $errorCode = $json.code
    $errorMessage = $json.message
    if ($errorCode -ne $ExpectedErrorCode) {
        throw "Unexpected Synapse RP error code: $errorCode ($errorMessage). Expecting: $ExpectedErrorCode."
    }
}

function SameForAll {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]
        $Sequence
    )
    $prev = $Null
    foreach ($item in $Sequence) {
        if ($Null -eq $prev) {
            $prev = $item
        }
        elseif ($prev -ne $item) {
            return $False
        }
    }
    return $True
}

$SessionId = [Guid]::NewGuid()
Write-Host "SessionId: $SessionId"

"SessionId: $SessionId" >> $OutputPath
"" >> $OutputPath

$TR = [Ordered]@{ }

Write-Host
Write-Host "  Please wait  " -ForegroundColor Black -BackgroundColor White
Write-Host

$SQL_POOL_DF_DOMAIN_SUFFIX = ".sql.azuresynapse-dogfood.net"
$SQL_ON_DEMAND_DF_DOMAIN_SUFFIX = "-ondemand.sql.azuresynapse-dogfood.net"

$SqlPoolDomainSuffix = ".sql.azuresynapse.net"
$SqlOnDemandDomainSuffix = "-ondemand.sql.azuresynapse.net"

try {
    $SessionIdSuffix = "&__session_id=$SessionId"
    Write-Host "Synapse Studio front-end"
    $TR.Studio0 = Test-Url GET http://web.azuresynapse.net {
        CheckStatusCode $_ 200
    }
    $TR.Studio1 = Test-Url GET https://web.azuresynapse.net {
        CheckStatusCode $_ 200
    }
    $TR.Studio2 = Test-Url GET https://web.azuresynapse.net/workspaces {
        CheckStatusCode $_ 200
    }

    Write-Host "Azure Management"
    $TR.AzureManagement1 = Test-Url GET https://management.azure.com/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-synapse-connectivity-dummy/providers/Microsoft.Synapse/workspaces/dummy/sqlPools?api-version=2019-06-01-preview$SessionIdSuffix {
        CheckStatusCode $_ 404
        Test-ArmErrorCode $_ SubscriptionNotFound
    } -Authorization

    $TR.AzureManagement1 = Test-Url GET https://management.azure.com/subscriptions/8b3b8a60-1dd0-4824-8770-2ed6a55d8e27/resourceGroups/test-synapse-connectivity-dummy/providers/Microsoft.Synapse/workspaces/dummy/sqlPools?api-version=2019-06-01-preview$SessionIdSuffix {
        CheckStatusCode $_ 401
        Test-ArmErrorCode $_ InvalidAuthenticationToken
    } -Authorization

    Write-Host "RBAC"
    $TR.RPAcl = Test-Url GET https://$Workspace.dev.azuresynapse.net/checkAccessSynapseRbac?api-version=2020-08-01-preview$SessionIdSuffix {
        CheckStatusCode $_ 401
        Test-RpErrorCode $_ AuthenticationFailed
    } -Authorization

    Write-Host "Spark Pool"
    $TR.RPSarkPool1 = Test-Url POST https://$Workspace.dev.azuresynapse.net/livyApi/versions/2019-11-01-preview/sparkPools/test-synapse-connectivity-dummy/sessions {
        CheckStatusCode $_ 401
        Test-RpErrorCode $_ AuthenticationFailed
    } -Authorization
    $TR.RPSarkPool2 = Test-Url GET https://$Workspace.dev.azuresynapse.net/livyApi/versions/2019-11-01-preview/sparkPools/test-synapse-connectivity-dummy/sessions/1 {
        CheckStatusCode $_ 401
        Test-RpErrorCode $_ AuthenticationFailed
    } -Authorization

    Write-Host "SQL Pool (443)"
    # Detect whether this workspace is using DF domain.
    if (-not (Resolve-DnsName "$Workspace$SqlPoolDomainSuffix" -ErrorAction Ignore)) {
        if ((Resolve-DnsName "$Workspace$SQL_POOL_DF_DOMAIN_SUFFIX" -ErrorAction Ignore)) {
            Write-Host "You SQL Pool server is on Dogfood domain."
            $SqlPoolDomainSuffix = $SQL_POOL_DF_DOMAIN_SUFFIX
        }
        else {
            Write-Host "No DNS record found for SQL Pool server." -ForegroundColor Yellow
        }
    }

    $TR.SqlPool1 = Test-Url OPTIONS -CorsMethod POST "https://$Workspace$SqlPoolDomainSuffix/databases/master/query?api-version=2018-08-01-preview&application=Test-SynapseConnectivity$SessionIdSuffix" {
        CheckStatusCode $_ 200
    }
    $TR.SqlPool2 = Test-Url POST "https://$Workspace$SqlPoolDomainSuffix/databases/master/query?api-version=2018-08-01-preview&application=Test-SynapseConnectivity$SessionIdSuffix" {
        CheckStatusCode $_ (400, 401)
        if ($_.Content -notmatch "The X-CSRF-Signature header could not be validated") {
            throw "Unexpected response: $($_.Content)"
        }
    } -Authorization

    Write-Host "SQL On-demand (443)"
    if (-not (Resolve-DnsName "$Workspace$SqlOnDemandDomainSuffix" -ErrorAction Ignore)) {
        if ((Resolve-DnsName "$Workspace$SQL_ON_DEMAND_DF_DOMAIN_SUFFIX" -ErrorAction Ignore)) {
            Write-Host "You SQL On-demand server is on Dogfood domain."
            $SqlOnDemandDomainSuffix = $SQL_ON_DEMAND_DF_DOMAIN_SUFFIX
        }
        else {
            Write-Host "No DNS record found for SQL On-demand server." -ForegroundColor Yellow
        }
    }

    $TR.SqlOnDemand1 = Test-Url OPTIONS -CorsMethod POST "https://$Workspace$SqlOnDemandDomainSuffix/databases/master/query?api-version=2018-08-01-preview&application=Test-SynapseConnectivity$SessionIdSuffix" {
        CheckStatusCode $_ 200
    }
    $TR.SqlOnDemand2 = Test-Url POST "https://$Workspace$SqlOnDemandDomainSuffix/databases/master/query?api-version=2018-08-01-preview&application=Test-SynapseConnectivity$SessionIdSuffix" {
        CheckStatusCode $_ (400, 401)
        if ($_.Content -notmatch "The X-CSRF-Signature header could not be validated") {
            throw "Unexpected response: $($_.Content)"
        }
    } -Authorization

    Write-Host "Power BI (443)"
    $TR.PowerBI1 = Test-Url GET "https://api.powerbi.com/v1.0/myorg/groups" {
        CheckStatusCode $_ (401, 403, 404)
    }
}
finally {
    if ($OutputPath) {
        "SqlPoolDomainSuffix: $SqlPoolDomainSuffix" >> $OutputPath
        "SqlOnDemandDomainSuffix: $SqlPoolDomainSuffix" >> $OutputPath
        "" >> $OutputPath
        $TR.Keys | % { "Test Result: $_"; $TR[$_] } >> $OutputPath
    }
}

Write-Host
Write-Host "  Summary  " -ForegroundColor Black -BackgroundColor White
Write-Host

if (($TR.Values | % { $_.Passed }) -notcontains $False) {
    Write-Host "The diagnostic script did not find any notable issues."
}
else {

    $TS = @{
        SameHostInstable = $False
    }

    Write-Host "One or more requests have failed to send. See the output above for technical details."
    Write-Host

    function ReportGeneralReachabilityIssue {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]
            $Authority,
            [Parameter(Mandatory = $true)]
            [object[]]
            $TestResults,
            [string]
            $NotFoundSuggestion
        )
        $Unreachable = $TestResults | ? { ! $_.Reachable }
        if (!(SameForAll ($TestResults | % { $_.Reachable }))) {
            $TS.SameHostInstable = $true
        }
        if ($Unreachable) {
            Write-Host "* Confirm whether your firewall has blocked access to " -NoNewline
            Write-Host $Authority -ForegroundColor Blue -NoNewline
            Write-Host "."
            # NoData from pwsh is related to DNS resolution issue. See WSANO_DATA for more information.
            if ($NotFoundSuggestion -and ($Unreachable | ? { $_.WebResponseStatus -in ("NameResolutionFailure", "HostNotFound", "NoData") })) {
                Write-Host $NotFoundSuggestion
            }
        }
        elseif ($TestResults | ? { ! $_.Passed }) {
            Write-Host "* Open "  -NoNewline
            Write-Host $Authority -ForegroundColor Blue -NoNewline
            Write-Host " in your browser, and check whether your firewall has blocked the access."
            if ($TestResults | ? { $_.Authorization -and -not $_.Passed -and $_.Exception -match "\bAuthorization\b" -or $_.Exception -match "\bBearerToken\b" }) {
                Write-Host '    * Check whether your firewall or network gateway has removed "Authorization" header from the outbound HTTP requests.'
            }
            Write-Host "    * Ensure you are using the latest troubleshooting script."
        }
    }

    if (!($TR.Studio1.Reachable -and $TR.Studio2.Reachable)) {
        Write-Host "* Confirm your network connectivity to https://web.azuresynapse.net."
    }
    elseif (!($TR.Studio1.Passed -and $TR.Studio2.Passed)) {
        Write-Host "* Confirm your whether you can open web.azuresynapse.net in your browser."
    }
    elseif (!$TR.Studio0.Passed) {
        Write-Host "* Confirm whether you have blocked access to non-https URL http://web.azuresynapse.net."
    }

    ReportGeneralReachabilityIssue "https://management.azure.com" ($TR.AzureManagement1, $TR.AzureManagement1)

    ReportGeneralReachabilityIssue "https://$Workspace.dev.azuresynapse.net" ($TR.RPAcl, $TR.RPSarkPool1, $TR.RPSarkPool2) -NotFoundSuggestion "* Check whether the workspace name you provided ($Workspace) is correct."

    # SQL Pool
    ReportGeneralReachabilityIssue "https://$Workspace$SqlPoolDomainSuffix" ($TR.SqlPool1, $TR.SqlPool2)

    # SQL OD
    ReportGeneralReachabilityIssue "https://$Workspace$SqlOnDemandDomainSuffix" ($TR.SqlOnDemand1, $TR.SqlOnDemand2) -NotFoundSuggestion '* If workspace name you provided is correct, your SQL On-demand instance may have not been created.
    * If you can confirm there is nothing wrong with your local network environment, you may need to contact support.
    '

    # SQL Pool / OD Timeout check
    if (($TR.SqlPool1, $TR.SqlPool2, $TR.SqlOnDemand1, $TR.SqlOnDemand2) | ? { $_.WebResponseStatus -eq "Timeout" }) {
        Write-Host "* Please retry running the script to see If SQL Pool / OD endpoint still times out."
    }

    # Power BI
    ReportGeneralReachabilityIssue "https://api.powerbi.com" ($TR.PowerBI1)

    if ($TS.SameHostInstable) {
        Write-Host "* Your network could be un-stable. Please try re-running the diagnsotic script."
    }
}
Write-Host

Write-Host "  General tips  " -ForegroundColor Black -BackgroundColor White
Write-Host '
* This script only tests for connectivity issues.
* Consider running the same test script 1) on the different machines in the same network environment
  and 2) on the same machine under different network environment (e.g. corporate network and Guest WiFi)
  to determine whether there are configuration issues with your local machine or local network environment.
* If the steps shown in "Summary" does not help, please contact support, providing the full diagnostic
  information shown above.'

if ($OutputPath) {
    Write-Host "* Full diagnostic information for this session has been written to " -NoNewline
    Write-Host $OutputPath -ForegroundColor Blue -NoNewline
    Write-Host "."
}

Pause
# return $TR
