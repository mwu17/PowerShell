# Please check the instruction at http://mikewu.org/powershell/trading-calculator-risk-management-reward-risk-ratio-powershell/

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Main function
function calculate {
    [CmdletBinding()]
    param
    (
        [double]$total2,
        [double]$entry2,
        [int]$shares2,
        [double]$target2,
        [double]$stop2,
        [double]$risk2,
        [double]$ratio2
    )
   
    # Calculate Risk%
    if(($entry2 -ne "") -and ($shares2 -ne "") -and ($Stop2 -ne "") -and ($risk2 -eq "")){
        if ($entry2 -lt $stop2) {
            [System.Windows.Forms.MessageBox]::Show("Entry Price must be greater than the Stop Price", "Invalid Values", 0, 48)
        }
        $entryCost = $entry2*$shares2
        $stoploss = $stop2*$shares2
        $riskper = ($entryCost-$stoploss)/$total2*100
        $risk.text= [math]::Round($riskper,3)
    }
    
    # Calculate Reward Risk Ratio
    elseif (($entry2 -ne "") -and ($target2 -ne "") -and ($stop2 -ne "") -and ($ratio2 -eq "")) {
        if ($entry2 -lt $stop2) {
            [System.Windows.Forms.MessageBox]::Show("Entry Price must be greater than the Stop Price", "Invalid Values", 0, 48)
        }
        if ($entry2 -gt $target2) {
            [System.Windows.Forms.MessageBox]::Show("Target Price must be greater than the Entry Price", "Invalid Values", 0, 48)
        }
        $riskCount = $entry2-$stop2
        $rewardCount = $target2-$entry2
        $ratioResult = $rewardCount/$riskCount
        $ratio.text = [math]::Round($ratioResult,3)
    }

    # Calculate Stop Price
    elseif (($entry2 -ne "") -and ($shares2 -ne "") -and ($risk2 -ne "") -and ($stop2 -eq "")) {
        $stopPrice = $entry2-(($total2*($risk2/100)/$shares2))
        $stop.text =  [math]::Round($stopPrice,3)
    }

    # Calculate Shares by the risk%
    elseif (($shares2 -eq "") -and ($entry2 -ne "") -and ($stop2 -ne "") -and ($risk2 -ne "") -and ($total2 -ne "")) {
        if ($entry2 -lt $stop2) {
            [System.Windows.Forms.MessageBox]::Show("Entry Price must be greater than the Stop Price", "Invalid Values", 0, 48)
        }
        $shares2 = ($total2*($risk2/100))/($entry2-$stop2)
        $shares.text = [math]::Round($shares2,0)
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Please Enter the required inputs.", "Missing Values", 0, 48)
    }
}

# Reset the amount except total fund
function reset-text () {
    $entry.clear()
    $shares.clear()
    $target.clear()
    $stop.clear()
    $risk.clear()
    $ratio.Clear()
    $total.clear()
}


# WPF GUI Windows
$inputXAML = @"
<Window x:Class="WpfApp1.MainWindow"
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
xmlns:local="clr-namespace:WpfApp1"
mc:Ignorable="d"
Title="Trading Calculator" Height="430.328" Width="378.688" ResizeMode="CanMinimize">
<Grid UseLayoutRounding="False">

<Border BorderBrush="Black" BorderThickness="1" HorizontalAlignment="Left" Height="357" Margin="10,10,0,0" VerticalAlignment="Top" Width="344" Background="#FFD1D1D1"/>

<Label Content="Total Fund : " HorizontalAlignment="Left" Height="30" Margin="18,28,0,0" VerticalAlignment="Top" Width="112" FontSize="18" FontWeight="Bold"/>
<Label Content="Entry Price : " HorizontalAlignment="Left" Height="36" Margin="18,111,0,0" VerticalAlignment="Top" Width="112" FontSize="18" FontWeight="Bold"/>
<Label Content="Stop Price : " HorizontalAlignment="Left" Height="40" Margin="17,197,0,0" VerticalAlignment="Top" Width="112" FontSize="18" FontWeight="Bold"/>
<Label Content="Risk % : " HorizontalAlignment="Left" Height="30" Margin="18,238,0,0" VerticalAlignment="Top" Width="112" FontSize="18" FontWeight="Bold"/>
<Label Content="Target Price : " HorizontalAlignment="Left" Height="37" Margin="18,152,0,0" VerticalAlignment="Top" Width="129" FontSize="18" FontWeight="Bold"/>
<Label Content="http://mikewu.org" HorizontalAlignment="Left" Height="24" Margin="10,367,0,0" VerticalAlignment="Top" Width="101" FontSize="11" FontStyle="Italic"/>
<Label Content="Reward Risk ratio : " HorizontalAlignment="Left" Height="30" Margin="18,279,0,0" VerticalAlignment="Top" Width="184" FontSize="18" FontWeight="Bold"/>
<Button x:Name="run" Content="Run" HorizontalAlignment="Left" Margin="140,325,0,0" VerticalAlignment="Top" Width="92" Height="31" FontWeight="Bold" FontSize="18" Foreground="White" Background="#FF0E349B"/>
<Button x:Name="reset" Content="Reset" HorizontalAlignment="Left" Margin="248,325,0,0" VerticalAlignment="Top" Width="92" Height="31" FontWeight="Bold" FontSize="18" Foreground="White" Background="#FFA03A14"/>
<TextBox x:Name="total" HorizontalAlignment="Left" Height="24" Margin="140,34,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="180" FontSize="16" FontWeight="Bold" TextAlignment="Center"/>
<TextBox x:Name="entry" HorizontalAlignment="Left" Height="24" Margin="140,117,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="180" FontSize="16" FontWeight="Bold" TextAlignment="Center"/>
<TextBox x:Name="target" HorizontalAlignment="Left" Height="24" Margin="139,158,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="180" FontSize="16" FontWeight="Bold" TextAlignment="Center"/>
<TextBox x:Name="stop" HorizontalAlignment="Left" Height="24" Margin="139,203,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="180" FontSize="16" FontWeight="Bold" TextAlignment="Center"/>
<TextBox x:Name="risk" HorizontalAlignment="Left" Height="24" Margin="140,244,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="180" FontSize="16" FontWeight="Bold" TextAlignment="Center"/>
<TextBox x:Name="ratio" HorizontalAlignment="Left" Height="24" Margin="199,285,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="120" FontSize="16" FontWeight="Bold" TextAlignment="Center"/>
<TextBox x:Name="shares" HorizontalAlignment="Left" Height="24" Margin="140,74,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="180" FontSize="16" FontWeight="Bold" TextAlignment="Center"/>
<Label Content="Shares : " HorizontalAlignment="Left" Height="30" Margin="18,69,0,0" VerticalAlignment="Top" Width="112" FontSize="18" FontWeight="Bold"/>

</Grid>
</Window>

"@

[xml]$Form = $inputXAML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'

$NR = (New-Object System.Xml.XmlNodeReader $Form)
$Win = [Windows.Markup.XamlReader]::Load($NR)

# Define variables
$total = $win.FindName("total")
$entry = $win.FindName("entry")
$target = $win.FindName("target")
$stop = $win.FindName("stop")
$risk = $win.FindName("risk")
$ratio = $win.FindName("ratio")
$shares = $win.FindName("shares")
$run = $win.FindName("run")
$reset = $win.FindName("reset")

# click the Run Button
$run.add_click( {
    calculate -total2 $total.text -entry2 $entry.text -target2 $target.text -stop2 $stop.text -risk2 $risk.text -shares2 $shares.text -ratio2 $ratio.text
})

$reset.add_click({
    reset-text
})


$Win.showdialog()