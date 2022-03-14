<#
 	.SYNOPSIS
      #################################################################################################################
      #                              Criador: Diogo De Santana Jacome                                                 #
      #                              Empresa:  CSU                                                                    #
      #                              Modifcado por: Diogo De Santana Jacome                                           #
      #                                                                                                               #
      #                                                                                                               #
      #                                          Versão: 1.0                                                          #
      #                                                                                                               #
      #                                                                                                               #
      #################################################################################################################  
      New-ConnectedVM is an advanced function that can be used to connect a Virtual Machine to hyper-v.
    
    .DESCRIPTION
         New-ConnectedVM is an advanced function that can be used to connect a Virtual Machine to hyper-v.
    
    
    .EXAMPLE
        C:\PS> New-ConnectedVM -VMName VM1 -StartVM
				
    .EXAMPLE
        C:\PS> New-ConnectedVM -Id 34d22d46-15c7-4226-9fa2-04f6c90a5a9a -StartVM
		
		.LINK 
        https://github.com/Didjacome
        
#>

function New-ConnectedVM {
  [CmdletBinding(DefaultParameterSetName = 'name')]

  param(
    [Parameter(ParameterSetName = 'name')]
    [Alias('cn')]
    [System.String[]]$ComputerName = $env:COMPUTERNAME,

    [Parameter(Position = 0,
      Mandatory, ValueFromPipelineByPropertyName,
      ValueFromPipeline, ParameterSetName = 'name')]
    [Alias('VMName')]
    [System.String]$Name,

    [Parameter(Position = 0,
      Mandatory, ValueFromPipelineByPropertyName,
      ValueFromPipeline, ParameterSetName = 'id')]
    [Alias('VMId', 'Guid')]
    [System.Guid]$Id,

    [Parameter(Position = 0, Mandatory,
      ValueFromPipeline, ParameterSetName = 'inputObject')]
    [Microsoft.HyperV.PowerShell.VirtualMachine]$InputObject,

    [switch]$StartVM
  )

  begin {
    Write-Verbose 'Initializing InstanceCount, InstanceCount = 0'
    $InstanceCount = 0
  }

  process {
    try {
      foreach ($computer in $ComputerName) {
        Write-Verbose "ParameterSetName is '$($PSCmdlet.ParameterSetName)'"
        if ((Get-Module hyper-v) -ne $true) { Import-Module hyper-v }

        if ($PSCmdlet.ParameterSetName -eq 'name') {
          # Get the VM by Id if Name can convert to a guid
          if ($Name -as [guid]) {
            Write-Verbose 'Incoming value can cast to guid'
            $vm = Get-VM -Id $Name -ErrorAction SilentlyContinue
          }
          else {
            $vm = Get-VM -Name $Name -ErrorAction SilentlyContinue
          }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'id') {
          $vm = Get-VM -Id $Id -ErrorAction SilentlyContinue
        }
        else {
          $vm = $InputObject
        }

        if ($vm) {
          Write-Verbose "Executing 'vmconnect.exe $computer $($vm.Name) -G $($vm.Id) -C $InstanceCount'"
          vmconnect.exe $computer $vm.Name -G $vm.Id -C $InstanceCount
        }
        else {
          Write-Verbose "Cannot find vm: '$Name'"
        }

        if ($StartVM -and $vm) {
          if ($vm.State -eq 'off') {
            Write-Verbose "StartVM was specified and VM state is 'off'. Starting VM '$($vm.Name)'"
            Start-VM -VM $vm
          }
          else {
            Write-Verbose "Starting VM '$($vm.Name)'. Skipping, VM is not not in 'off' state."
          }
        }

        $InstanceCount += 1
        Write-Verbose "InstanceCount = $InstanceCount"
      }
    }
    catch {
      Write-Error $_
    }
  }

}