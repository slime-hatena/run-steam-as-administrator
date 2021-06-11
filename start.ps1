param (
    [Parameter(Mandatory=$True)][String]$gamePath,
    [Parameter(Mandatory=$True)][String]$gameProcessName,
    [Parameter(Mandatory=$True)][String]$steamGameID,
    [Parameter(Mandatory=$False)][String]$steamPath = "C:\Program Files (x86)\Steam\steam.exe",
    [Parameter(Mandatory=$False)][String]$steamProcessName = "steam"
)

Add-Type -Assembly System.Windows.Forms;

Write-Host "ParamList";
Write-Host "  gamePath: " $gamePath;
Write-Host "  gameProcessName: " $gameProcessName;
Write-Host "  steamGameID: " $steamGameID;
Write-Host "  steamPath: " $steamPath;
Write-Host "  steamProcessName: " $steamProcessName;
Write-Host "";

Function Get-Process-Wait($name) {
    Write-Host "Search process name: " $name;
    $c = 0;
    do {
        # 指定回数プロセスを取得できなかったら起動失敗ということにする
        if (++$c -gt 5) {
            $message = $name + 'の起動を確認できませんでした。';
            $dialogResult = [System.Windows.Forms.MessageBox]::Show($message, "起動失敗", "RetryCancel", "Error", "button1");
            if ($dialogResult -eq [System.Windows.Forms.DialogResult]::Cancel) {
                exit;
            }
            # [System.Windows.Forms.DialogResult]::Retry
            Write-Host "Retry";
            $c = 1;
        }

        Start-Sleep -s 2;
        Write-Host "Try:" $c;
        $process = Get-Process -Name $name -ErrorAction SilentlyContinue;
    } while (!$?);
    return $process;
}

Function Disappear-Process-Wait($name) {
    do {
        # プロセスが取得できなくなったら終了したと見なす
        Start-Sleep -s 5;
        Get-Process -Name $name -ErrorAction SilentlyContinue;
    } while ($?);
}

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
    Write-Host "管理者権限では起動していません";
    Get-Process -Name $steamProcessName -ErrorAction SilentlyContinue | Stop-Process;
    Start-Process $steamPath -Verb runAs;
    Get-Process-Wait $steamProcessName;
    Start-Process ('steam://rungameid/' + $steamGameID);

    Write-Host "ゲームの終了を待機します";
    Get-Process-Wait $gameProcessName;
    Disappear-Process-Wait $gameProcessName;
    Disappear-Process-Wait $steamProcessName;
    Write-Host "ゲームと管理者権限Steamの終了を確認";
    Start-Sleep -s 2;
    Start-Process $steamPath
} else {
    Write-Host "管理者権限で起動しています";
    Start-Process $gamePath;
    Get-Process-Wait $gameProcessName;
    Disappear-Process-Wait $gameProcessName;
    Get-Process -Name $steamProcessName -ErrorAction SilentlyContinue | Stop-Process;
}

Write-Host "exit";
Start-Sleep -s 60;
