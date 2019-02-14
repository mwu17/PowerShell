<#
.SYNOPSIS
    Show Firewall rules from the remote computer
.DESCRIPTION
    Show Firewall rules from the remote computer
.EXAMPLE
    Get-FirewallRules -ComputerName dsc-tst1 |ft
    DisplayName                                                      RemoteAddress                    Protocol LocalPort PSComputerName RunspaceId
-----------                                                      -------------                    -------- --------- -------------- ----------
BranchCache Content Retrieval (HTTP-In)                          Any                              TCP      80        dsc-tst1       effd348e-b5a8-4f88-bca5-17b264639201
BranchCache Hosted Cache Server (HTTP-In)                        Any                              TCP      {80, 443} dsc-tst1       effd348e-b5a8-4f88-bca5-17b264639201
BranchCache Peer Discovery (WSD-In)                              LocalSubnet                      UDP      3702      dsc-tst1       effd348e-b5a8-4f88-bca5-17b264639201
COM+ Network Access (DCOM-In)                                    Any                              TCP      135       dsc-tst1       effd348e-b5a8-4f88-bca5-17b264639201
COM+ Remote Administration (DCOM-In)                             Any                              TCP      RPC       dsc-tst1       effd348e-b5a8-4f88-bca5-17b264639201
Distributed Transaction Coordinator (RPC)                        Any                              TCP      RPC       dsc-tst1       effd348e-b5a8-4f88-bca5-17b264639201
Distributed Transaction Coordinator (RPC-EPMAP)                  Any                              TCP      RPCEPMap  dsc-tst1       effd348e-b5a8-4f88-bca5-17b264639201
Distributed Transaction Coordinator (TCP-In)                     Any                              TCP      Any       dsc-tst1       effd348e-b5a8-4f88-bca5-17b264639201
File and Printer Sharing (Echo Request - ICMPv4-In)              Any                              ICMPv4   RPC       dsc-tst1       effd348e-b5a8-4f88-bca5-17b264639201
File and Printer Sharing (Echo Request - ICMPv6-In)              Any                              ICMPv6   RPC       dsc-tst1       effd348e-b5a8-4f88-bca5-17b264639201
File and Printer Sharing (LLMNR-UDP-In)                          LocalSubnet                      UDP      5355      dsc-tst1       effd348e-b5a8-4f88-bca5-17b264639201
File and Printer Sharing (NB-Datagram-In)                        Any                              UDP      138       dsc-tst1       effd348e-b5a8-4f88-bca5-17b264639201
File and Printer Sharing (NB-Name-In)                            Any                              UDP      137       dsc-tst1       effd348e-b5a8-4f88-bca5-17b264639201
File and Printer Sharing (NB-Session-In)                         Any                              TCP      139       dsc-tst1       effd348e-b5a8-4f88-bca5-17b264639201
File and Printer Sharing (SMB-In)                                Any                              TCP      445       dsc-
.EXAMPLE
$a = Get-FirewallRules -ComputerName dsc-tst1
Save the firewall rules for later query. for example...

PS C:\> $a | ? displayname -eq "Allow TCP 80 for test"

DisplayName    : Allow TCP 80 for test
RemoteAddress  : Any
Protocol       : TCP
LocalPort      : 80
PSComputerName : DSC-TST1
RunspaceId     : 21cb465e-2029-41ba-9026-401c893f898d
.EXAMPLE
Get-FirewallRules dsc-tst1|? localport -Contains 80|ft


DisplayName           RemoteAddress                     Protocol LocalPort PSComputerName RunspaceId
-----------           -------------                     -------- --------- -------------- ----------
Allow TCP 80 for test Any                               TCP      80        DSC-TST1       d458e7dd-4703-43e6-9cb1-6a407c262150
Test FW               {10.10.10.10, 10.10.1.2, 1.1.1.1} TCP      {80, 443} DSC-TST1       d458e7dd-4703-43e6-9cb1-6a407c262150
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    Created By Michael Wu https://mikewu.org/powershell/use-powershell-to-get-firewall-rules-from-remote-computer-get-firewallrules/
#>

function Get-FirewallRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName = $env:computername,

        # Parameter help description
        [Parameter(Mandatory = $false,
        HelpMessage="This parameter specifies that the rule object is administratively enabled or administratively disabled. Default is True")]
        [ValidateSet("True", "False")]
        [string]$Enabled = "True"
    )
    
    begin {
        # Test if the server is online and PowerShell remoting is enabled
        if (Test-Connection $ComputerName -Quiet -Count 1) {
        }
        else {
            Write-Host "$ComputerName is offline..." -ForegroundColor Red
            break
        }
        if (Test-WSMan $ComputerName -ErrorAction SilentlyContinue) {
        }
        else {
            Write-Host "PowerShell Remoting is disabled..." -ForegroundColor Red
            break
        }
    }
    
    process {
        $rules = Invoke-Command $ComputerName -ScriptBlock {
            $FWObjs = @()
            $fws = Get-NetFirewallRule -Direction Inbound -PolicyStore ActiveStore -Action Allow -Enabled $args[0]

            foreach ($fw in $fws) {
                $remoteAddress = $fw | Get-NetFirewallAddressFilter | Select-Object -ExpandProperty RemoteAddress
                $protocol = $fw | Get-NetFirewallPortFilter | Select-Object -ExpandProperty Protocol
                $localPort = $fw | Get-NetFirewallPortFilter | Select-Object -ExpandProperty LocalPort
                $fw|Add-Member -MemberType NoteProperty -Name Protocol -Value $protocol
                $fw|Add-Member -MemberType NoteProperty -Name LocalPort -Value $localPort
                $fw|Add-Member -MemberType NoteProperty -Name RemoteAddress -Value $remoteAddress
                $FWObjs += $fw
            }
            $FWObjs|Sort-Object displayname|Where-Object displayname -NotLike "@{Microsoft.*"|Select-Object displayname, RemoteAddress, Protocol, LocalPort 


        } -ArgumentList $Enabled
        
        $rules
    }
    
    end {
    }
}