Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# SCOM Management Server Input
#$SCOMMgmtSvr = "YourManagementServer.yourDomainName"
$SCOMMgmtSvr = Read-Host "Please enter your SCOM Management Server name"

New-SCOMManagementGroupConnection -ComputerName $SCOMMgmtSvr

#region Action functions

# List All Maintenance Windows Servers
function get-allMMServers () {
    $MMGrid.clear()
    $MMobj=@()
    $MM_servers = Get-SCOMClass –Name Microsoft.Windows.Computer | Get-SCOMClassInstance | where-object {$_.InMaintenanceMode -eq $true}
    foreach($mm_server in $MM_servers){
        $mm_server2 = $mm_server|Get-SCOMMaintenanceMode
        $obj = [PSCustomObject]@{
            ServerName = $mm_server.name
            StartTime = Get-LocalTime $mm_server2.StartTime
            ScheduledEndTime = Get-LocalTime $mm_server2.ScheduledEndTime
            User = $mm_server2.user
            Reason = $mm_server2.reason
            Comments = $mm_server2.comments
        }
        $MMobj+=$obj
    }
    $MMGrid.ItemsSource = $MMobj
}

# Search non MM servers
function search-server ($Name) {
    $serverGrid.ItemsSource = ""
    $searchResult = Get-SCOMClass –Name Microsoft.Windows.Computer | Get-SCOMClassInstance | where-object {$_.DisplayName -like "*$Name*" -and $_.InMaintenanceMode -eq $false}|Select-Object name,HealthState,StateLastModified,IsAvailable,AvailabilityLastModified,TimeAdded|Sort-Object name

    if($searchResult -eq $null){
        [System.Windows.Forms.MessageBox]::Show("No search results." , "No result",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)
        $serverName.clear()
    }
    else{
        $serverGrid.ItemsSource = $searchResult
    }
}

# Clear all text
function clearAll () {
    $serverName.clear()
    $duration.clear()
    $serverGrid.ItemsSource = ""
    $comment.clear()
    $reason.SelectedIndex = 0
    $scheduledEndTime.clear()
}

# Convert UTC time to Local time
Function Get-LocalTime($UTCTime) {
    $strCurrentTimeZone = (Get-WmiObject win32_timezone).StandardName
    $TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($strCurrentTimeZone)
    $LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, $TZ)
    Return $LocalTime
}


# Scheduled End Time WinForm
function Schedule-TimeForm () {
    # Main Form
    $mainForm = New-Object System.Windows.Forms.Form
    $font = New-Object System.Drawing.Font("Consolas", 13)
    $mainForm.Text = "Pick End Time"
    $mainForm.Font = $font
    $mainForm.ForeColor = "White"
    $mainForm.BackColor = "gray"
    $mainForm.Width = 450
    $mainForm.Height = 120

    # DatePicker Label
    $datePickerLabel = New-Object System.Windows.Forms.Label
    $datePickerLabel.Text = "Date : "
    $datePickerLabel.Location = "15, 10"
    $datePickerLabel.Height = 22
    $datePickerLabel.Width = 90
    $mainForm.Controls.Add($datePickerLabel)

    # TimePicker Label
    $TimePickerLabel = New-Object System.Windows.Forms.Label
    $TimePickerLabel.Text = "Time : "
    $TimePickerLabel.Location = "15, 45"
    $TimePickerLabel.Height = 22
    $TimePickerLabel.Width = 90
    $mainForm.Controls.Add($TimePickerLabel)

    # DatePicker
    $datePicker = New-Object System.Windows.Forms.DateTimePicker
    $datePicker.Location = "110, 7"
    $datePicker.Width = "300"
    $datePicker.Format = [windows.forms.datetimepickerFormat]::custom
    $datePicker.CustomFormat = "dddd,MMMM dd,yyyy"
    $mainForm.Controls.Add($datePicker)

    # TimePicker
    $TimePicker = New-Object System.Windows.Forms.DateTimePicker
    $TimePicker.Location = "110, 42"
    $TimePicker.Width = "150"
    $TimePicker.Format = [windows.forms.datetimepickerFormat]::custom
    $TimePicker.CustomFormat = "HH:mm:ss tt"
    $TimePicker.ShowUpDown = $TRUE
    $mainForm.Controls.Add($TimePicker)


    # OK Button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = "300, 45"
    $okButton.ForeColor = "Black"
    $okButton.BackColor = "White"
    $okButton.Text = "OK"
    $okButton.add_Click({$mainForm.close()})
    $mainForm.Controls.Add($okButton)

    [void] $mainForm.ShowDialog()

    return [datetime]$scheduleTime = $datePicker.text +" "+ $TimePicker.Text
}

#endregion

# WPF GUI Windows
$inputXAML = @"

<Window

        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:SCOM_GUI"

        mc:Ignorable="d"
        Title="SCOM Maintenance Mode GUI Tool" Height="447.059" Width="907.353">
    <Grid>
        <TabControl x:Name="tabControl" HorizontalAlignment="Left" Height="416" VerticalAlignment="Top" Width="899">
            <TabItem Header="Start Maintenance Mode">
                <Grid Background="#FFE5E5E5">
                    <TextBox x:Name="serverName" HorizontalAlignment="Left" Height="25" Margin="33,24,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" FontSize="14"/>
                    <Button x:Name="search" Content="Search" HorizontalAlignment="Left" Height="25" Margin="329,24,0,0" VerticalAlignment="Top" Width="119" FontWeight="Bold" FontSize="14" Foreground="White" BorderBrush="#FF403B3B" Background="#FF4F4848"/>
                    <DataGrid x:Name="serverGrid" HorizontalAlignment="Left" Height="114" Margin="33,59,0,0" VerticalAlignment="Top" Width="826" Background="#FFF0F0F0" BorderThickness="0"/>
                    <TextBox x:Name="duration" HorizontalAlignment="Left" Height="24" Margin="40,222,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="109" FontSize="14"/>
                    <GroupBox x:Name="groupBox1" Header="Name : " HorizontalAlignment="Left" Height="182" Margin="21,0,0,0" VerticalAlignment="Top" Width="846" FontSize="14">
                        <Button x:Name="reset" Content="Reset" HorizontalAlignment="Left" Margin="438,4,0,0" VerticalAlignment="Top" Width="115" Height="25" Foreground="White" Background="#FFB60E3C" FontWeight="Bold"/>
                    </GroupBox>
                    <GroupBox x:Name="groupBox2" Header="Duration (minutes) : " HorizontalAlignment="Left" Height="69" Margin="21,192,0,0" VerticalAlignment="Top" Width="147" FontSize="14"/>
                    <GroupBox x:Name="groupBox3" Header="Specific end time : " HorizontalAlignment="Left" Height="69" Margin="184,192,0,0" VerticalAlignment="Top" Width="342" FontSize="14">
                        <Button x:Name="TimePickButton" Content="Select" HorizontalAlignment="Left" Margin="268,10,0,0" VerticalAlignment="Top" Width="55" Height="25" Foreground="#FFF7F7F7" Background="#FF4F4848" FontWeight="Bold"/>
                    </GroupBox>
                    <GroupBox x:Name="groupBox4" Header="Reason : " HorizontalAlignment="Left" Height="69" Margin="540,192,0,0" VerticalAlignment="Top" Width="327" FontSize="14">
                        <ComboBox x:Name="reason" HorizontalAlignment="Left" Height="22" Margin="7,10,0,0" VerticalAlignment="Top" Width="300">
                            <ComboBoxItem Content="PlannedOther"/>
                            <ComboBoxItem Content="UnplannedOther"/>
                            <ComboBoxItem Content="PlannedHardwareMaintenance"/>
                            <ComboBoxItem Content="UnplannedHardwareMaintenance"/>
                            <ComboBoxItem Content="PlannedHardwareInstallation"/>
                            <ComboBoxItem Content="UnplannedHardwareInstallation"/>
                            <ComboBoxItem Content="PlannedOperatingSystemReconfiguration"/>
                            <ComboBoxItem Content="UnplannedOperatingSystemReconfiguration"/>
                            <ComboBoxItem Content="PlannedApplicationMaintenance"/>
                            <ComboBoxItem Content="ApplicationInstallation"/>
                            <ComboBoxItem/>
                            <ComboBoxItem Content="ApplicationUnresponsive"/>
                            <ComboBoxItem Content="ApplicationUnstable"/>
                            <ComboBoxItem Content="SecurityIssue"/>
                            <ComboBoxItem Content="LossOfNetworkConnectivity"/>
                            <ComboBoxItem/>
                        </ComboBox>
                    </GroupBox>
                    <GroupBox x:Name="groupBox5" Header="Comments : " HorizontalAlignment="Left" Height="89" Margin="21,276,0,0" VerticalAlignment="Top" Width="505" FontSize="14">
                        <TextBox x:Name="comment" HorizontalAlignment="Left" Height="50" Margin="10,10,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="469" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto"/>
                    </GroupBox>
                    <Button x:Name="start" Content="Start Maintenance Mode" HorizontalAlignment="Left" Height="73" Margin="592,292,0,0" VerticalAlignment="Top" Width="247" FontSize="18" FontWeight="Bold" Background="#FF19A626" Foreground="White" BorderBrush="White"/>
                    <TextBox x:Name="ScheduledEndTime" HorizontalAlignment="Left" Height="25" Margin="202,222,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="246" IsReadOnly="True"/>
                </Grid>
            </TabItem>
            <TabItem Header="Stop Maintenance Mode">
                <Grid Background="#FFE5E5E5">
                    <DataGrid x:Name="MMGrid" HorizontalAlignment="Left" Height="268" Margin="32,29,0,0" VerticalAlignment="Top" Width="830"/>
                    <Button x:Name="stop" Content="Stop Maintenance Mode" HorizontalAlignment="Left" Height="37" Margin="508,322,0,0" VerticalAlignment="Top" Width="212" FontWeight="Bold" FontSize="14" Background="#FF9B0829" Foreground="White" BorderBrush="White"/>
                    <Button x:Name="refresh" Content="Refresh" HorizontalAlignment="Left" Height="37" Margin="742,322,0,0" VerticalAlignment="Top" Width="120" FontSize="14" FontWeight="Bold" Background="#FF4F4848" Foreground="White" BorderBrush="#FFFBFBFB"/>
                    <GroupBox x:Name="groupBox" Header="Maintenance Mode Servers" HorizontalAlignment="Left" Height="306" Margin="18,5,0,0" VerticalAlignment="Top" Width="856" FontSize="14"/>
                </Grid>
            </TabItem>
        </TabControl>

    </Grid>
</Window>


"@

# Munge to remove what PowerShell doesn't like and cast as XML
#     Remove design-time ignorable tags
#     Convert "x:Name" nodes to "Name"
#     Remove Window classing
[xml]$Form = $inputXAML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'




$NR=(New-Object System.Xml.XmlNodeReader $Form)
$Win=[Windows.Markup.XamlReader]::Load($NR)

# PS Variables
$serverName = $win.findname("serverName")
$search = $win.findname("search")
$serverGrid = $win.findname("serverGrid")
$duration = $win.findname("duration")
$reason = $win.findname("reason")
$comment = $win.findname("comment")
$start = $win.findname("start")
$MMGrid = $win.findname("MMGrid")
$stop = $win.findname("stop")
$refresh = $win.findname("refresh")
$scheduledEndTime = $win.findname("ScheduledEndTime")
$TimePickButton = $win.findname("TimePickButton")
$reset = $win.findname("reset")


#region Actions Control
$refresh.Add_Click({
        get-allMMServers
        [System.Windows.Forms.MessageBox]::Show("Refresh done." , "Refresh",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Asterisk)
    })

$search.Add_Click({
        search-server -Name $serverName.text
    })

$start.Add_Click({

        $selectedItem = $serverGrid.Selecteditem.Name

        # Validate Duration time format
        try {
            [int]$duration.text
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Please enter the correct time format." , "Durantion time error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
            $duration.clear()
            return
        }

        # Validate server name
        if($serverGrid.selectedvalue -eq $null){
            [System.Windows.Forms.MessageBox]::Show("Please select a server" , "No server name error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        }
        # Validate duration time minimum
        elseif ($duration.text -ne "" -and [int]$duration.text -lt 5) {
            [System.Windows.Forms.MessageBox]::Show("Please enter at least 5 minutes." , "Durantion time error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
            $duration.clear()
        }
        elseif($duration.text -eq "" -and $scheduledEndTime.text -eq ""){
            [System.Windows.Forms.MessageBox]::Show("Please enter the end time." , "End time error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        }
        else {
            $instance = Get-SCOMClassInstance -Name $selectedItem
            $now = Get-Date
            if($scheduledEndTime.text -ne ""){
                $time = $scheduledEndTime.text -as [datetime]
            }
            else {
                $time = $now.AddMinutes($duration.text)
            }

            $displayText ="
            Are you sure to start Maintenance Mode?
            Server: $($selectedItem)
            End time: $time
            Reason: $($reason.text)
            Comment: $($comment.text)
            "
            $confirm = [System.Windows.Forms.MessageBox]::Show($displayText , "Start Maintenance Mode" , 1)
            if($confirm -eq "OK"){
                # Fixed error by adding ".ToUniversalTime()"
                Start-SCOMMaintenanceMode -Instance $instance -EndTime $time.ToUniversalTime() -Reason $reason.text -Comment $comment.text -Verbose
                [System.Windows.Forms.MessageBox]::Show("Maintenance Mode Started" , "Maintenance Mode",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Asterisk)
                clearAll
                get-allMMServers
            }
        }

    })

$stop.Add_Click({
        $selectedItem2 = $MMGrid.Selecteditem.serverName
        $confirm = [System.Windows.Forms.MessageBox]::Show("Are you sure to STOP Maintenance Mode on $selectedItem2 ?" , "Stop Maintenance Mode" , 1)
        if($confirm -eq "OK"){
            $computer = Get-SCOMClass –Name Microsoft.Windows.Computer | Get-SCOMClassInstance | where-object {$_.DisplayName -like "*$selectedItem2*" -and $_.InMaintenanceMode -eq $true}
            $computer.StopMaintenanceMode([DateTime]::Now.ToUniversalTime(),[Microsoft.EnterpriseManagement.Common.TraversalDepth]::Recursive)
            [System.Windows.Forms.MessageBox]::Show("Maintenance Mode Stoped" , "Maintenance Mode",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Asterisk)
            # Refresh
            get-allMMServers
        }
    })

$TimePickButton.Add_Click({
        $scheduledEndTime.clear()
        $endtime = Schedule-TimeForm
        $scheduledEndTime.text = $endtime
    })

$reset.Add_Click({
        clearAll
    })
#endregion

get-allMMServers

$reason.SelectedIndex = 0

$Win.showdialog()