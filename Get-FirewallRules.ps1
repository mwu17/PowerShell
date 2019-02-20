<#
.SYNOPSIS
    Show Firewall rules from the remote computer
.DESCRIPTION
    Show Firewall rules from the remote computer
.EXAMPLE
Get-FirewallRules dsc-tst1

DisplayName                                                                RemoteAddress                                                       Protocol LocalPort
-----------                                                                -------------                                                       -------- ---------
Allow TCP 80 for test                                                      Any                                                                 TCP      80
Core Networking - Destination Unreachable (ICMPv6-In)                      Any                                                                 ICMPv6   RPC
Core Networking - Destination Unreachable Fragmentation Needed (ICMPv4-In) Any                                                                 ICMPv4   RPC
Core Networking - Dynamic Host Configuration Protocol (DHCP-In)            Any                                                                 UDP      68
Core Networking - Dynamic Host Configuration Protocol for IPv6(DHCPV6-In)  Any                                                                 UDP      546
Core Networking - Internet Group Management Protocol (IGMP-In)             Any                                                                 2        Any
Core Networking - IPHTTPS (TCP-In)                                         Any                                                                 TCP      IPHTTPSIn
Core Networking - IPv6 (IPv6-In)                                           Any                                                                 41       Any
Core Networking - Multicast Listener Done (ICMPv6-In)                      LocalSubnet6                                                        ICMPv6   RPC
Core Networking - Multicast Listener Query (ICMPv6-In)                     LocalSubnet6                                                        ICMPv6   RPC
Core Networking - Multicast Listener Report (ICMPv6-In)                    LocalSubnet6                                                        ICMPv6   RPC
Core Networking - Multicast Listener Report v2 (ICMPv6-In)                 LocalSubnet6                                                        ICMPv6   RPC
Core Networking - Neighbor Discovery Advertisement (ICMPv6-In)             Any                                                                 ICMPv6   RPC
Core Networking - Neighbor Discovery Solicitation (ICMPv6-In)              Any                                                                 ICMPv6   RPC
Core Networking - Packet Too Big (ICMPv6-In)                               Any                                                                 ICMPv6   RPC
Core Networking - Parameter Problem (ICMPv6-In)                            Any                                                                 ICMPv6   RPC
Core Networking - Router Advertisement (ICMPv6-In)                         fe80::/64                                                           ICMPv6   RPC
Core Networking - Router Solicitation (ICMPv6-In)                          Any                                                                 ICMPv6   RPC
Core Networking - Teredo (UDP-In)                                          Any                                                                 UDP      Teredo
Core Networking - Time Exceeded (ICMPv6-In)                                Any                                                                 ICMPv6   RPC
.EXAMPLE
Get-FirewallRules -ComputerName dsc-tst1 -Name "Core*" -LocalPort RPC

DisplayName                                                                RemoteAddress Protocol LocalPort
-----------                                                                ------------- -------- ---------
Core Networking - Destination Unreachable (ICMPv6-In)                      Any           ICMPv6   RPC
Core Networking - Destination Unreachable Fragmentation Needed (ICMPv4-In) Any           ICMPv4   RPC
Core Networking - Multicast Listener Done (ICMPv6-In)                      LocalSubnet6  ICMPv6   RPC
Core Networking - Multicast Listener Query (ICMPv6-In)                     LocalSubnet6  ICMPv6   RPC
Core Networking - Multicast Listener Report (ICMPv6-In)                    LocalSubnet6  ICMPv6   RPC
Core Networking - Multicast Listener Report v2 (ICMPv6-In)                 LocalSubnet6  ICMPv6   RPC
Core Networking - Neighbor Discovery Advertisement (ICMPv6-In)             Any           ICMPv6   RPC
Core Networking - Neighbor Discovery Solicitation (ICMPv6-In)              Any           ICMPv6   RPC
Core Networking - Packet Too Big (ICMPv6-In)                               Any           ICMPv6   RPC
Core Networking - Parameter Problem (ICMPv6-In)                            Any           ICMPv6   RPC
Core Networking - Router Advertisement (ICMPv6-In)                         fe80::/64     ICMPv6   RPC
Core Networking - Router Solicitation (ICMPv6-In)                          Any           ICMPv6   RPC
Core Networking - Time Exceeded (ICMPv6-In)                                Any           ICMPv6   RPC

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

        # Parameter return Enabled firewall rules
        [Parameter(Mandatory = $false,
            HelpMessage = "This parameter specifies that the rule object is administratively enabled or administratively disabled. Default is True")]
        [ValidateSet("True", "False")]
        [string]$Enabled = "True",

        # Firewall rule name
        [Parameter(Mandatory = $false)]
        [string]
        $Name = "",

        # Firewall rule protocol
        [Parameter(Mandatory = $false)]
        [String]
        $Protocol = "",

        # Firewall rule Port
        [Parameter(Mandatory = $false)]
        [String]
        $LocalPort = "",

        # Firewall rule RemoteAddress
        [Parameter(Mandatory = $false)]
        [String]
        $RemoteAddress = ""
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
                $remoteAddress2 = $fw | Get-NetFirewallAddressFilter | select -ExpandProperty RemoteAddress
                $protocol2 = $fw | Get-NetFirewallPortFilter | select -ExpandProperty Protocol
                $localPort2 = $fw | Get-NetFirewallPortFilter | select -ExpandProperty LocalPort
                $fw|Add-Member -MemberType NoteProperty -Name Protocol -Value $protocol2
                $fw|Add-Member -MemberType NoteProperty -Name LocalPort -Value $localPort2
                $fw|Add-Member -MemberType NoteProperty -Name RemoteAddress -Value $remoteAddress2
                $FWObjs += $fw
            }
            $FWObjs|sort displayname|Where-Object displayname -NotLike "@{Microsoft.*"|select displayname, RemoteAddress, Protocol, LocalPort 

        } -ArgumentList $Enabled
        
        # Firewall rule fileter - switch
        switch ($true) {
            (($name -ne "") -and ($Protocol -eq "") -and ($LocalPort -eq "") -and ($RemoteAddress -eq "")) 
            {$rules|sort displayname|Where-Object displayname -Like $name|select displayname, RemoteAddress, Protocol, LocalPort }

            (($name -ne "") -and ($Protocol -ne "") -and ($LocalPort -eq "") -and ($RemoteAddress -eq "")) 
            {$rules|sort displayname|Where-Object displayname -Like $name|? protocol -EQ $protocol|select displayname, RemoteAddress, Protocol, LocalPort }

            (($name -ne "") -and ($Protocol -eq "") -and ($LocalPort -ne "") -and ($RemoteAddress -eq "")) 
            {$rules|sort displayname|Where-Object displayname -Like $name|? LocalPort -Contains $LocalPort|select displayname, RemoteAddress, Protocol, LocalPort }

            (($name -ne "") -and ($Protocol -eq "") -and ($LocalPort -eq "") -and ($RemoteAddress -ne "")) 
            {$rules|sort displayname|Where-Object displayname -Like $name|? RemoteAddress -Contains $RemoteAddress|select displayname, RemoteAddress, Protocol, LocalPort }

            (($name -ne "") -and ($Protocol -ne "") -and ($LocalPort -ne "") -and ($RemoteAddress -eq "")) 
            {$rules|sort displayname|Where-Object displayname -Like $name|? protocol -EQ $protocol|? LocalPort -Contains $LocalPort|select displayname, RemoteAddress, Protocol, LocalPort }

            (($name -ne "") -and ($Protocol -ne "") -and ($LocalPort -ne "") -and ($RemoteAddress -ne "")) 
            {$rules|sort displayname|Where-Object displayname -Like $name|? protocol -EQ $protocol|? LocalPort -Contains $LocalPort|? RemoteAddress -Contains $RemoteAddress|select displayname, RemoteAddress, Protocol, LocalPort }

            (($name -ne "") -and ($Protocol -EQ "") -and ($LocalPort -ne "") -and ($RemoteAddress -ne "")) 
            {$rules|sort displayname|Where-Object displayname -Like $name|? LocalPort -Contains $LocalPort|? RemoteAddress -Contains $RemoteAddress|select displayname, RemoteAddress, Protocol, LocalPort }

            (($name -ne "") -and ($Protocol -ne "") -and ($LocalPort -eq "") -and ($RemoteAddress -ne "")) 
            {$rules|sort displayname|Where-Object displayname -Like $name|? protocol -EQ $protocol|? RemoteAddress -Contains $RemoteAddress|select displayname, RemoteAddress, Protocol, LocalPort }

            ########
        
            (($name -eq "") -and ($Protocol -eq "") -and ($LocalPort -eq "") -and ($RemoteAddress -eq "")) 
            {$rules|sort displayname|select displayname, RemoteAddress, Protocol, LocalPort }

            (($name -eq "") -and ($Protocol -ne "") -and ($LocalPort -eq "") -and ($RemoteAddress -eq "")) 
            {$rules|sort displayname|? protocol -EQ $protocol|select displayname, RemoteAddress, Protocol, LocalPort }

            (($name -eq "") -and ($Protocol -eq "") -and ($LocalPort -ne "") -and ($RemoteAddress -eq "")) 
            {$rules|sort displayname|? LocalPort -Contains $LocalPort|select displayname, RemoteAddress, Protocol, LocalPort }

            (($name -eq "") -and ($Protocol -eq "") -and ($LocalPort -eq "") -and ($RemoteAddress -ne "")) 
            {$rules|sort displayname|? RemoteAddress -Contains $RemoteAddress|select displayname, RemoteAddress, Protocol, LocalPort }

            (($name -eq "") -and ($Protocol -ne "") -and ($LocalPort -ne "") -and ($RemoteAddress -eq "")) 
            {$rules|sort displayname|? protocol -EQ $protocol|? LocalPort -Contains $LocalPort|select displayname, RemoteAddress, Protocol, LocalPort }

            (($name -eq "") -and ($Protocol -ne "") -and ($LocalPort -ne "") -and ($RemoteAddress -ne "")) 
            {$rules|sort displayname|? protocol -EQ $protocol|? LocalPort -Contains $LocalPort|? RemoteAddress -Contains $RemoteAddress|select displayname, RemoteAddress, Protocol, LocalPort }

            (($name -eq "") -and ($Protocol -EQ "") -and ($LocalPort -ne "") -and ($RemoteAddress -ne "")) 
            {$rules|sort displayname|? LocalPort -Contains $LocalPort|? RemoteAddress -Contains $RemoteAddress|select displayname, RemoteAddress, Protocol, LocalPort }

            (($name -eq "") -and ($Protocol -ne "") -and ($LocalPort -eq "") -and ($RemoteAddress -ne "")) 
            {$rules|sort displayname|? protocol -EQ $protocol|? RemoteAddress -Contains $RemoteAddress|select displayname, RemoteAddress, Protocol, LocalPort }

            Default {$rules|sort displayname|select displayname, RemoteAddress, Protocol, LocalPort }
        }
        
    }
    
    end {
    }
}