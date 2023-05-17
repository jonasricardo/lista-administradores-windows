param(
	$hostFile,
	$outputFile = ".\saida.csv",
	[switch]$help
)

function help {
	Write-Host ""
	Write-Host "Script para listagem de membros do grupo administradores em máquinas windows"
	Write-Host ""
	Write-Host "Parâmetros:"
	Write-Host "	-hostFile <arquivo>		Caminho de arquivo contendo nome das máquinas alvo (uma por linha)"
	Write-Host "	-outputFile <arquivo>	Caminho de arquivo CSV de saída, se não informado será salvo o arquivo saida.csv no diretório de execução do script"
	Write-Host ""
	Write-Host "Observações:"
	Write-Host "	Script deve ser executado com usuário com acesso administrativo nas máquinas de destino"
	Write-Host "	multiplas execuções apontando para o mesmo arquivo de saída irá realizar apend das informações"
}

if($help){
	help
	exit 0
}

if($hostFile -eq $null){
	Write-Host "parâmetro hostFile não foi passado"

	help
	exit 1
}
if(!(Test-path $hostFile)){
	Write-Host "Caminho do arquivo de hostFile não existe"
	
	help
	exit 2
}

$GroupName = "Administradores"

$maquinas = Get-Content -Path $hostFile

foreach ($maquina in $maquinas){
	
	if($maquina -eq ""){
		continue
	}

	if(Test-Connection -ComputerName $maquina -Count 1 -Quiet){
		try{

		$Group = [ADSI]"WinNT://$maquina/$GroupName,group"
		
		$members = $Group.Invoke("members") | forEach-Object {
			([ADSI]$_)
		}

		foreach($m in $members){
			$result = [PSCustomObject]@{
				Host = $maquina
				Status = "OK"
				#Nome = $($m.Name)
				Path = $($m.Path.remove(0,8))
				Class = $($m.Class)
			}
			
			$result | Export-Csv -Path $outputFile -NoTypeInformation -Append
		}
		
		}
		catch {
			
			$result = [PSCustomObject]@{
				Host = $maquina
				Status = $($_.Exception.Message)
				#Nome = ""
				Path = ""
				Class = ""
			}
			$result | Export-Csv -Path $outputFile -NoTypeInformation -Append
			

		}
	} else {
		$result = [PSCustomObject]@{
				Host = $maquina
				Status = "Offline"
				#Nome = ""
				Path = ""
				Class = ""
			}
			$result | Export-Csv -Path $outputFile -NoTypeInformation -Append
	}

}