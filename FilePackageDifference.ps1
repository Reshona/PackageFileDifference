
class CreateCsv{

[void]PrintToCsv($value,$y1,$y2,$filex,$filey,$fileName) {
    Write-Host "`r`in PrintToCsv`r`n" -ForegroundColor yellow
    for($i = 0; $i -lt $value; $i++) {
    $wrapper = New-Object PSObject -Property @{ $filex = $y1[$i]; $filey = $y2[$i] }

    Export-Csv -InputObject $wrapper -Path "..\$fileName.csv" -NoTypeInformation -Append
    }
}

[int]CountLength($y1, $y2) {
    Write-Host "`r`nin CountLength`r`n" -ForegroundColor yellow
    $count = 0
    if ($y1.Length -gt $y2.Length) {$count = $y1.Length}
    else {$count = $y2.Length}
    echo $count
    return $count
    }

[int]CheckForDepth($file1, $file2){
        Write-Host "`r`nin CheckforDepth`r`n" -ForegroundColor yellow
        $flag = 0
        7z l $file1 *.zip *.tar *.7z -r0 |select-object -Skip 15 | Select-object -SkipLast 2  > ".\WorkDir\IsZip1.txt"
        7z l $file2 *.zip *.tar *.7z -r0 |select-object -Skip 15 | Select-object -SkipLast 2  > ".\WorkDir\isZip2.txt" 
        If (((Get-Content "WorkDir\isZip1.txt") -and (Get-Content "WorkDir\isZip2.txt")) -eq "") {
            echo "both files don't have any child archives setting flag as 1"
            $flag = 1 
        }
        return $flag 
    }

[array]PlainZip($filex,$filey,$fileName){
    Write-Host "`r`n inPlainZip $filex,$filey,$fileName`r`n" -ForegroundColor yellow
    $PWD = pwd 
    Write-host "$PWD"
    echo "if flag == 1"
    7z l $filex  |select-object -Skip 15 | Select-object -SkipLast 2  > ".\WorkDir\NoArchive1List.txt"
    7z l $filey  |select-object -Skip 15 | Select-object -SkipLast 2  > ".\WorkDir\NoArchive2List.txt"
    cd WorkDir
    $data1 = get-content "NoArchive1List.txt"
    $y1= @()
    $data2 = get-content "NoArchive2List.txt"
    $y2= @()
    foreach($line1 in $data1 )
    {
       if ( $line1.length -gt 50){ $y1 += $line1.substring(53) }
    }
   foreach($line2 in $data2)
    {
       if ( $line2.length -gt 50){ $y2 += $line2.substring(53) } 
    }  
      Return $y1,$y2
    
    }


[array]CheckPath($path){
        Write-host "in CheckPath" -BackgroundColor DarkYellow
        $flag2 = 0
        $filevalue = @()
        cd $path     
        7z l . | select-string -Pattern 'Path' > a.txt
        $filevalue = ((gc .\a.txt -raw ) -replace "(?m)^\s*`r`n",'').trim() 
        if ($filevalue -ne "") {        
            return $filevalue
            $flag2 = 1
        }
        else {
             $flag2 = 0
            return $flag2
            
        }
    }

[Void]ExtractArchive(){
        Write-host "in ExtractArchive" -BackgroundColor DarkYellow
        $path = '.'
        ((gc a.txt -raw) -replace "(?m)^\s*`r`n",'').trim() | Set-Content a.txt
        $files = gc a.txt
        foreach ($i in $files) {
        if ($i -ne ""){
            $Path2 = $i.Substring(7)
            $P2fname = $Path2.Substring(2,$Path2.Length-6)
            Write-host $Path2 
            7z x $Path2 -o"$P2fname"
            rm -r -fo $Path2 
            continue
            }
        else {
             Write-host "done" -BackgroundColor Cyan
             continue
                
              }  
        }

    }

[void]CopyFiles($file1,$file2){
        copy $file1 .\WorkDir
        copy $file2 .\WorkDir
        cd .\WorkDir
    }

}

$file1= Read-Host "enter the 1st filename"
$file2= Read-Host "enter the 2nd filename"
$fileName= Read-host "enter the name of the csv file to create"
Write-Host "`r`nfiles selected are $file1 and $file2`r`n" -ForegroundColor green
$tc = New-Object -TypeName CreateCsv

mkdir WorkDir
$depthValue = $tc.CheckForDepth($file1,$file2)

if ($depthValue -eq 1 ) {
Write-Host "`r`n depth value is 1`r`n" -ForegroundColor green
 $y1= @()
 $y2=@()
    $y1,$y2=$tc.PlainZip($file1,$file2,$fileName)
    $value = $tc.CountLength($y1,$y2)
    $tc.PrintToCsv($value,$y1,$y2,$file1,$file2,$fileName)
    cd ..
}

else {
$path = "."
$tc.CopyFiles($file1,$file2)
echo "in else"
Write-Host "`r`n depth value is 0`r`n" -ForegroundColor green
    while (((Test-Path (dir -r *.zip)) -ne $null)) {
        $tc.CheckPath($path)
        $tc.ExtractArchive()
        rm a.txt
        continue

        }

$file5= $file1.Substring(0,$file1.length-4)
$file6= $file2.Substring(0,$file2.length-4) 
       

7z a -t7z "$file5.7z" .\$file5\* -r

7z a -t7z "$file6.7z" .\$file6\* -r
cd ..
$y3= @()
$y4=@()

    $file3 = ".\WorkDir\$file5.7z"
    $file4 = ".\WorkDir\$file6.7z"
    $y3,$y4=$tc.PlainZip("$file3","$file4",$fileName)
    $value = $tc.CountLength($y3,$y4)
    $tc.PrintToCsv($value,$y3,$y4,"$file3","$file4",$fileName)
cd ..

}
rm -r -fo .\WorkDir