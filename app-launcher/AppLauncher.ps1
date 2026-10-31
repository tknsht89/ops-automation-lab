$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$apps = @(
    [PSCustomObject]@{Name='Gemini'; Kind='Web'; Id='kbcggiilocbihjojgjmllfdfmappblch'}
    [PSCustomObject]@{Name='GitHub'; Kind='Web'; Id='mjoklplbddabcmpepnokjaffbmgbkkgg'}
    [PSCustomObject]@{Name='TryHackMe'; Kind='Web'; Id='eanbcgbkojijadfomfbjlimjbaliofco'}
    [PSCustomObject]@{Name='Gmail'; Kind='Web'; Id='fmgjjmmmlfnkbppncabfkddbjimcfncm'}
    [PSCustomObject]@{Name='Google ドライブ'; Kind='Web'; Id='aghbiahbpaijignceidepookljebhfak'}
    [PSCustomObject]@{Name='Google マップ'; Kind='Web'; Id='mnhkaebcjjhencmpkapnbdaogjamfbcj'}
    [PSCustomObject]@{Name='X'; Kind='Web'; Id='lodlkdfmihgonocnmddehnfgiljnadcf'}
    [PSCustomObject]@{Name='YouTube'; Kind='Web'; Id='agimnkijcaahngcdmfeangaknmldooml'}
    [PSCustomObject]@{Name='はてなブログ'; Kind='Web'; Id='mpehdobhmdnmchfmbbpdcpecoahhceic'}
    [PSCustomObject]@{Name='Google フォト'; Kind='Web'; Id='ncmjhecbjeaamljdfahankockkkdmedg'}
    [PSCustomObject]@{Name='NotebookLM'; Kind='Web'; Id='kjfmejlnnfibknebffpdmphoiomckhdb'}
)
$windowsNames = @('Burp Suite','Claude','DaVinci Resolve','DeepL','Disney+','Duolingo','Google Chrome','Netflix','OBS Studio','Perplexity','Screenpresso','Slack','TradingView','Visual Studio Code','Wintoys','カメラ','サウンド レコーダー','スマートフォン連携')
foreach ($name in $windowsNames) {
    $apps += [PSCustomObject]@{Name=$name; Kind='Windows'; Id=''}
}
$form = New-Object System.Windows.Forms.Form
$form.Text = 'アプリ一括起動'
$form.ClientSize = New-Object System.Drawing.Size(620, 740)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font('Yu Gothic UI', 10)
$label = New-Object System.Windows.Forms.Label
$label.Text = '使うアプリにチェックして「選択したアプリを起動」を押してください。'
$label.SetBounds(15, 12, 590, 35)
$list = New-Object System.Windows.Forms.CheckedListBox
$list.SetBounds(15, 50, 590, 470)
$list.CheckOnClick = $true
$list.IntegralHeight = $false
foreach ($app in $apps) { [void]$list.Items.Add($app.Name, $false) }
$launch = New-Object System.Windows.Forms.Button
$launch.Text = '選択したアプリを起動'
$launch.SetBounds(15, 530, 265, 40)
$clear = New-Object System.Windows.Forms.Button
$clear.Text = 'チェックをすべて外す'
$clear.SetBounds(295, 530, 200, 40)
$close = New-Object System.Windows.Forms.Button
$close.Text = '閉じる'
$close.SetBounds(505, 530, 100, 40)
$log = New-Object System.Windows.Forms.TextBox
$log.SetBounds(15, 580, 590, 145)
$log.Multiline = $true
$log.ReadOnly = $true
$log.ScrollBars = 'Vertical'
$log.Text = 'まだ何も起動していません。起動結果は各アプリの画面でも確認してください。'
$clear.Add_Click({ for ($i=0; $i -lt $list.Items.Count; $i++) { $list.SetItemChecked($i, $false) } })
$close.Add_Click({ $form.Close() })
$launch.Add_Click({
    $selected = @($list.CheckedIndices | ForEach-Object { $apps[[int]$_] })
    if ($selected.Count -eq 0) {
        [void][System.Windows.Forms.MessageBox]::Show('アプリを1つ以上選んでください。', '確認')
        return
    }
    $launch.Enabled = $false
    $clear.Enabled = $false
    $list.Enabled = $false
    try {
        $log.Clear()
        $installed = @(Get-StartApps -ErrorAction Stop)
        foreach ($app in $selected) {
            try {
                if ($app.Kind -eq 'Web') {
                    $proxy = Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome_proxy.exe'
                    if (-not (Test-Path -LiteralPath $proxy)) { throw 'Chromeの起動ファイルが見つかりません。' }
                    Start-Process -FilePath $proxy -ArgumentList "--profile-directory=Default --app-id=$($app.Id)" -ErrorAction Stop
                } else {
                    $match = @($installed | Where-Object { $_.Name -eq $app.Name })
                    if ($match.Count -ne 1) { throw '起動先が見つからないか、候補が複数あります。' }
                    $windowsShell = New-Object -ComObject Shell.Application
                    $appsFolder = $windowsShell.Namespace('shell:AppsFolder')
                    if ($null -eq $appsFolder) { throw 'Windowsのアプリ一覧を取得できません。' }
                    $appItem = $appsFolder.ParseName([string]$match[0].AppID)
                    if ($null -eq $appItem) { throw '対象アプリの起動項目が見つかりません。' }
                    $appItem.InvokeVerb('open')
                }
                $log.AppendText("起動要求を送信: $($app.Name)`r`n")
            } catch {
                $log.AppendText("エラー: $($app.Name) - $($_.Exception.Message)`r`n")
            }
        }
        for ($i=0; $i -lt $list.Items.Count; $i++) { $list.SetItemChecked($i, $false) }
        $log.AppendText('処理終了。実際に開いたか、各アプリの画面を確認してください。')
    } catch {
        $log.AppendText("処理エラー: $($_.Exception.Message)")
    } finally {
        $launch.Enabled = $true
        $clear.Enabled = $true
        $list.Enabled = $true
    }
})
$form.Controls.AddRange([System.Windows.Forms.Control[]]@($label,$list,$launch,$clear,$close,$log))
[void]$form.ShowDialog()
$form.Dispose()
