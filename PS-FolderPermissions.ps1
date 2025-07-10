# File Server Klasör Yetkileri Analiz Scripti @onderakoz
# Domain üyesi file server'da üst klasörlere kimlerin yetkilerinin olduğunu analiz eder

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


$form = New-Object System.Windows.Forms.Form
$form.Text = "File Server Klasör Yetkileri Analizi"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"


$labelPath = New-Object System.Windows.Forms.Label
$labelPath.Location = New-Object System.Drawing.Point(10, 10)
$labelPath.Size = New-Object System.Drawing.Size(100, 20)
$labelPath.Text = "Klasör Yolu:"
$form.Controls.Add($labelPath)


$textBoxPath = New-Object System.Windows.Forms.TextBox
$textBoxPath.Location = New-Object System.Drawing.Point(120, 10)
$textBoxPath.Size = New-Object System.Drawing.Size(400, 20)
$textBoxPath.Text = "C:\"
$form.Controls.Add($textBoxPath)


$buttonBrowse = New-Object System.Windows.Forms.Button
$buttonBrowse.Location = New-Object System.Drawing.Point(530, 8)
$buttonBrowse.Size = New-Object System.Drawing.Size(75, 25)
$buttonBrowse.Text = "Gözat"
$form.Controls.Add($buttonBrowse)


$buttonAnalyze = New-Object System.Windows.Forms.Button
$buttonAnalyze.Location = New-Object System.Drawing.Point(615, 8)
$buttonAnalyze.Size = New-Object System.Drawing.Size(75, 25)
$buttonAnalyze.Text = "Analiz Et"
$form.Controls.Add($buttonAnalyze)


$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Location = New-Object System.Drawing.Point(10, 50)
$dataGridView.Size = New-Object System.Drawing.Size(770, 400)
$dataGridView.AutoSizeColumnsMode = "Fill"
$dataGridView.ReadOnly = $true
$dataGridView.AllowUserToAddRows = $false
$form.Controls.Add($dataGridView)


$buttonExport = New-Object System.Windows.Forms.Button
$buttonExport.Location = New-Object System.Drawing.Point(10, 460)
$buttonExport.Size = New-Object System.Drawing.Size(100, 30)
$buttonExport.Text = "CSV Export"
$buttonExport.Enabled = $false
$form.Controls.Add($buttonExport)


$buttonExportExcel = New-Object System.Windows.Forms.Button
$buttonExportExcel.Location = New-Object System.Drawing.Point(120, 460)
$buttonExportExcel.Size = New-Object System.Drawing.Size(100, 30)
$buttonExportExcel.Text = "Excel Export"
$buttonExportExcel.Enabled = $false
$form.Controls.Add($buttonExportExcel)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 500)
$progressBar.Size = New-Object System.Drawing.Size(770, 20)
$progressBar.Style = "Continuous"
$form.Controls.Add($progressBar)


$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 530)
$statusLabel.Size = New-Object System.Drawing.Size(770, 20)
$statusLabel.Text = "Hazır"
$form.Controls.Add($statusLabel)


$global:results = @()


function Convert-FileSystemRights {
    param([System.Security.AccessControl.FileSystemRights]$Rights)
    
    $rightsList = @()
    
    if ($Rights -band [System.Security.AccessControl.FileSystemRights]::FullControl) {
        $rightsList += "Tam Kontrol"
    } else {
        if ($Rights -band [System.Security.AccessControl.FileSystemRights]::Read) { $rightsList += "Okuma" }
        if ($Rights -band [System.Security.AccessControl.FileSystemRights]::Write) { $rightsList += "Yazma" }
        if ($Rights -band [System.Security.AccessControl.FileSystemRights]::Execute) { $rightsList += "Çalıştırma" }
        if ($Rights -band [System.Security.AccessControl.FileSystemRights]::Delete) { $rightsList += "Silme" }
        if ($Rights -band [System.Security.AccessControl.FileSystemRights]::Modify) { $rightsList += "Değiştirme" }
        if ($Rights -band [System.Security.AccessControl.FileSystemRights]::ReadAndExecute) { $rightsList += "Okuma ve Çalıştırma" }
        if ($Rights -band [System.Security.AccessControl.FileSystemRights]::ListDirectory) { $rightsList += "Listeleme" }
        if ($Rights -band [System.Security.AccessControl.FileSystemRights]::CreateFiles) { $rightsList += "Dosya Oluşturma" }
        if ($Rights -band [System.Security.AccessControl.FileSystemRights]::CreateDirectories) { $rightsList += "Klasör Oluşturma" }
        if ($Rights -band [System.Security.AccessControl.FileSystemRights]::ReadPermissions) { $rightsList += "Yetki Okuma" }
        if ($Rights -band [System.Security.AccessControl.FileSystemRights]::ChangePermissions) { $rightsList += "Yetki Değiştirme" }
        if ($Rights -band [System.Security.AccessControl.FileSystemRights]::TakeOwnership) { $rightsList += "Sahiplik Alma" }
    }
    
    return ($rightsList -join ", ")
}


function Convert-InheritanceFlags {
    param([System.Security.AccessControl.InheritanceFlags]$Inheritance)
    
    switch ($Inheritance) {
        "None" { return "Devralmaz" }
        "ContainerInherit" { return "Alt Klasörlere Devralır" }
        "ObjectInherit" { return "Dosyalara Devralır" }
        "ContainerInherit, ObjectInherit" { return "Tüm Alt Öğelere Devralır" }
        default { return $Inheritance.ToString() }
    }
}


function Convert-PropagationFlags {
    param([System.Security.AccessControl.PropagationFlags]$Propagation)
    
    switch ($Propagation) {
        "None" { return "Kısıtlamasız" }
        "NoPropagateInherit" { return "Bir Alt Seviye" }
        "InheritOnly" { return "Sadece Devralma" }
        default { return $Propagation.ToString() }
    }
}


function Get-FolderPermissions {
    param(
        [string]$Path,
        [int]$MaxDepth = 3
    )
    
    $results = [System.Collections.ArrayList]@()
    $statusLabel.Text = "Analiz başlatılıyor..."
    $progressBar.Value = 0
    
    function Get-PermissionsRecursive {
        param(
            [string]$CurrentPath,
            [int]$CurrentDepth
        )
        
        try {
            if ($CurrentDepth -gt $MaxDepth) { return }
            
            # ACL bilgilerini al
            $acl = Get-Acl -Path $CurrentPath
            
            foreach ($access in $acl.Access) {
                # Sadece Allow türündeki yetkileri al
                if ($access.AccessControlType -eq "Allow") {
                    $userInfo = $access.IdentityReference.ToString()
                    
                    # Domain kullanıcısı mı kontrol et
                    $isDomainUser = $userInfo -match "^[^\\]+\\[^\\]+$" -and $userInfo -notmatch "^BUILTIN\\" -and $userInfo -notmatch "^NT AUTHORITY\\"
                    
                    $result = [PSCustomObject]@{
                        'Klasör' = $CurrentPath
                        'Kullanıcı/Grup' = $userInfo
                        'Yetki' = Convert-FileSystemRights -Rights $access.FileSystemRights
                        'Yetki Kodu' = $access.FileSystemRights.value__
                        'Devralma' = Convert-InheritanceFlags -Inheritance $access.InheritanceFlags
                        'Yayılma' = Convert-PropagationFlags -Propagation $access.PropagationFlags
                        'Domain Kullanıcısı' = if ($isDomainUser) { "Evet" } else { "Hayır" }
                        'Derinlik' = $CurrentDepth
                    }
                    $results.Add($result) | Out-Null
                }
            }
            
            # Alt klasörleri tara
            if ($CurrentDepth -lt $MaxDepth) {
                $subfolders = Get-ChildItem -Path $CurrentPath -Directory -ErrorAction SilentlyContinue
                foreach ($subfolder in $subfolders) {
                    Get-PermissionsRecursive -CurrentPath $subfolder.FullName -CurrentDepth ($CurrentDepth + 1)
                }
            }
        }
        catch {
            Write-Host "Hata: $CurrentPath - $_" -ForegroundColor Red
        }
    }
    
    Get-PermissionsRecursive -CurrentPath $Path -CurrentDepth 0
    return $results.ToArray()
}


$buttonBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Analiz edilecek klasörü seçin"
    $folderBrowser.SelectedPath = $textBoxPath.Text
    
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $textBoxPath.Text = $folderBrowser.SelectedPath
    }
})


$buttonAnalyze.Add_Click({
    $path = $textBoxPath.Text
    
    if (-not (Test-Path $path)) {
        [System.Windows.Forms.MessageBox]::Show("Belirtilen klasör bulunamadı!", "Hata", "OK", "Error")
        return
    }
    
    $statusLabel.Text = "Analiz ediliyor..."
    $progressBar.Style = "Marquee"
    $buttonAnalyze.Enabled = $false
    
    # Arka planda analiz yap
    $global:results = Get-FolderPermissions -Path $path
    
    # DataGridView'a sonuçları yükle
    $dataGridView.DataSource = $global:results
    
    $statusLabel.Text = "Analiz tamamlandı. Toplam " + $global:results.Count + " yetki kaydı bulundu."
    $progressBar.Style = "Continuous"
    $progressBar.Value = 100
    $buttonAnalyze.Enabled = $true
    $buttonExport.Enabled = $true
    $buttonExportExcel.Enabled = $true
})


$buttonExport.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "CSV Files (*.csv)|*.csv"
    $saveDialog.FileName = "FileServer_Permissions_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".csv"
    
    if ($saveDialog.ShowDialog() -eq "OK") {
        try {
            $global:results | Export-Csv -Path $saveDialog.FileName -NoTypeInformation -Encoding UTF8
            [System.Windows.Forms.MessageBox]::Show("CSV dosyası başarıyla kaydedildi!", "Başarılı", "OK", "Information")
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("CSV export hatası: $_", "Hata", "OK", "Error")
        }
    }
})

$buttonExportExcel.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "Excel Files (*.xlsx)|*.xlsx"
    $saveDialog.FileName = "FileServer_Permissions_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".xlsx"
    
    if ($saveDialog.ShowDialog() -eq "OK") {
        try {
            # Excel COM Object kullanarak export
            $excel = New-Object -ComObject Excel.Application
            $excel.Visible = $false
            $workbook = $excel.Workbooks.Add()
            $worksheet = $workbook.Worksheets.Item(1)
            $worksheet.Name = "Klasör Yetkileri"
            
            # Başlıkları yaz
            $headers = @("Klasör", "Kullanıcı/Grup", "Yetki", "Yetki Kodu", "Devralma", "Yayılma", "Domain Kullanıcısı", "Derinlik")
            for ($i = 0; $i -lt $headers.Length; $i++) {
                $worksheet.Cells.Item(1, $i + 1) = $headers[$i]
            }
            
            # Verileri yaz
            for ($row = 0; $row -lt $global:results.Count; $row++) {
                $worksheet.Cells.Item($row + 2, 1) = $global:results[$row].'Klasör'
                $worksheet.Cells.Item($row + 2, 2) = $global:results[$row].'Kullanıcı/Grup'
                $worksheet.Cells.Item($row + 2, 3) = $global:results[$row].'Yetki'
                $worksheet.Cells.Item($row + 2, 4) = $global:results[$row].'Yetki Kodu'
                $worksheet.Cells.Item($row + 2, 5) = $global:results[$row].'Devralma'
                $worksheet.Cells.Item($row + 2, 6) = $global:results[$row].'Yayılma'
                $worksheet.Cells.Item($row + 2, 7) = $global:results[$row].'Domain Kullanıcısı'
                $worksheet.Cells.Item($row + 2, 8) = $global:results[$row].'Derinlik'
            }
            
            # Otomatik genişlik ayarla
            $worksheet.UsedRange.EntireColumn.AutoFit()
            
            # Kaydet ve kapat
            $workbook.SaveAs($saveDialog.FileName)
            $workbook.Close()
            $excel.Quit()
            
            [System.Windows.Forms.MessageBox]::Show("Excel dosyası başarıyla kaydedildi!", "Başarılı", "OK", "Information")
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Excel export hatası: $_", "Hata", "OK", "Error")
        }
        finally {
            # COM objelerini temizle
            if ($excel) {
                [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
            }
            [System.GC]::Collect()
        }
    }
})

$form.ShowDialog()
