[CmdletBinding()]param()

Import-Module PSAINT # http://poshcode.org/Modules/PSAINT.psd1

Import-Module "$PSScriptRoot\..\ModuleInfo.psm1" -ErrorAction Stop

test "Get-ModuleInfo Adds Simple Names" {
   arrange {
      $ModuleInfo = Get-ModuleInfo PSAINT
   }
   act {
      $RequiredModules = $ModuleInfo.RequiredModules | Select -First 1
   }
   assert {
      "Name = Reflection".MustEqual( ("Name = " + $RequiredModules.Name) )
   }
} -Category AddSimpleNames


# test "ImportModuleInfo Adds Simple Names" {
#    arrange {
#       $ModuleInfo = Get-ModuleInfo PSAINT | Select -First 1
#       $ModuleManifest = ImportModuleInfo $ModuleInfo.Path
#    }
#    act {
#       $RequiredModules = $ModuleManifest.RequiredModules | Select -First 1
#    }
#    assert {
#       "Name = Reflection".MustEqual( ("Name = " + $RequiredModules.Name) )
#    }
# } -Category AddSimpleNames
#
#
# test "ImportModuleInfo Imports Package Manifest" {
#    arrange {
#       $ModuleInfo = Get-ModuleInfo PSAINT | Select -First 1
#       $ModuleManifest = ImportModuleInfo $ModuleInfo.Path
#    }
#    act {
#       $RequiredModules = $ModuleManifest.RequiredModules | Select -First 1
#    }
#    assert {
#       "Name = Reflection".MustEqual( ("Name = " + $RequiredModules.Name) )
#
#       "http://poshcode.org/Modules/PSAINT.psd1".MustEqual( $ModuleManifest.PackageInfoUrl )
#       "http://PoshCode.org/Modules/Reflection.psdxml".MustEqual( $RequiredModules.PackageInfoUrl )
#    }
# } -Category AddSimpleNames



test "Get-ModuleInfo Supports Packages Includes Both Manifest" {
   arrange {
      $ModulePackage = "~\Documents\WindowsPowerShell\Modules\WASP.nupkg"
      
      if(!(Test-Path $ModulePackage)) {
         $null = Invoke-WebRequest -Uri "http://poshcode.org/Modules/WASP-2.0.0.6.nupkg" -OutFile $ModulePackage
      }
   }
   act {
      $ModuleManifest = Get-ModuleInfo $ModulePackage
      $RequiredModules = $ModuleManifest.RequiredModules | Select -First 1
   }
   assert {
      "Name = Reflection".MustEqual( ("Name = " + $RequiredModules.Name) )
      "http://poshcode.org/Modules/WASP.psd1".MustEqual( $ModuleManifest.PackageInfoUrl )
      "http://PoshCode.org/Modules/Reflection.psd1".MustEqual( $RequiredModules.PackageInfoUrl )
   }
} -Category Packages



test "Get-ModuleInfo As Object" {
   arrange {
      $ModulePackage = "~\Documents\WindowsPowerShell\Modules\WASP.nupkg"
      
      if(!(Test-Path $ModulePackage)) {
         $null = Invoke-WebRequest -Uri "http://poshcode.org/Modules/WASP-2.0.0.6.nupkg" -OutFile $ModulePackage
      }
      $ModuleManifest = Get-ModuleInfo $ModulePackage
   }
   act {
      $RequiredModules = $ModuleManifest.RequiredModules | Select -First 1
   }
   assert {
      "Name = Reflection".MustEqual( ("Name = " + $RequiredModules.Name) )

      "http://poshcode.org/Modules/WASP.psd1".MustEqual( $ModuleManifest.PackageInfoUrl )
      "http://PoshCode.org/Modules/Reflection.psd1".MustEqual( $RequiredModules.PackageInfoUrl )
   }
} -Category Packages

test "Convert Simple Hashtable to Metadata" {
   arrange {

      $table = @{ 
                  one = 'uno'; two = "dos"
                  three = 'three'
               }

      $truth = "@{",
               "  one = 'uno'",
               "  two = 'dos'",
               "  three = 'three'",
               "}"
   }
   act {
      $result = ConvertTo-Metadata $table
   }
   assert {
      # It's not that they can be in ANY order, but the values can be
      # This is just simpler than trying to sort only the hashtable content
      $truth = ($truth | sort ) -join "`n"
      $result = (($result -split "[\r\n]+") | sort ) -join "`n"

      $truth.MustEqual($result)
   }
} -Category Serialize


test "Arrays and Hashtables" {
   arrange {
      $table = @(
                  @{ 
                     one = "uno"; two = "dos"
                     three = @( 'wan', 'too', 'tres', 'quatro')
                     num = 1, 2, 3, 4 
                  }, "Porkay?"
               )
      $truth = "@(@{",
               "  one = 'uno'",
               "  two = 'dos'",
               "  three = @('wan','too','tres','quatro')",
               "  num = @(1,2,3,4)",
               "},'Porkay?')"
   }
   act {
      $result = ConvertTo-Metadata $table
   }
   assert {
      # It's not that they can be in ANY order, but the values can be
      # This is just simpler than trying to sort only the hashtable content
      $truth = ($truth | sort ) -join "`n"
      $result = (($result -split "[\r\n]+") | sort ) -join "`n"

      $truth.MustEqual($result)
   }
} -Category Serialize


test "Numbers And Deep Nesting" {
   arrange {
      $table = @{ 
                  russian = @{
                     nesting = @{
                        dolls = @{
                           are = @{
                              4 = 'quatro'
                              3 = 'tres'
                              2 = 'too'
                              1 = 'wan'
                           }
                        }
                     }
                  }
               }
      $truth = "@{`n" +
               "  russian = @{`n" +
               "    nesting = @{`n" +
               "      dolls = @{`n" +
               "        are = @{`n" +
               "          4 = 'quatro'`n" +
               "          3 = 'tres'`n" +
               "          2 = 'too'`n" +
               "          1 = 'wan'`n" +
               "        }`n" +
               "      }`n" +
               "    }`n" +
               "  }`n" +
               "}"
   }
   act {
      $result = ConvertTo-Metadata $table
   }
   assert {
      $truth.MustEqual($result)
   }
} -Category Serialize



test "Real Data Test: Curly braces " {
   arrange {
      $table = @{ 
                  InstallPaths = @{
                     CommonPath = "{ProgramFiles}\WindowsPowerShell\Modules"
                     UserPath = "{MyDocuments}\WindowsPowerShell\Modules"
                  }
                  Repositories = @{
                     FileSystem = "\\PoshCode.org\Modules"
                  }
               }
      $truth = "@{",
               "  InstallPaths = @{",
               "    CommonPath = '{ProgramFiles}\WindowsPowerShell\Modules'",
               "    UserPath = '{MyDocuments}\WindowsPowerShell\Modules'",
               "  }",
               "  Repositories = @{",
               "    FileSystem = '\\PoshCode.org\Modules'",
               "  }",
               "}"
   }
   act {
      $result = ConvertTo-Metadata $table
   }
   assert {
      # It's not that they can be in ANY order, but the values can be
      # This is just simpler than trying to sort only the hashtable content
      $truth = ($truth | sort ) -join "`n"
      $result = (($result -split "[\r\n]+") | sort ) -join "`n"

      $truth.MustEqual($result)
   }
} -Category Serialize

test "Custom Converters" {
   arrange {
      $CustomObject = New-Object PSObject -Property @{ FirstName = "Joel"; LastName = "Bennett"; Age = 39; }
      $Guid = [Guid]::NewGuid()
      $Now = Get-Date

      $table = @{
                  InstallPaths = @{
                     CommonPath = '{ProgramFiles}\WindowsPowerShell\Modules'
                     UserPath = '{MyDocuments}\WindowsPowerShell\Modules'
                  }
                  Repositories = @{
                     FileSystem = '\\PoshCode.org\Modules', 'P:\Modules'
                  }
                  Custom = $CustomObject
                  Guid = $Guid
                  Culture = $PSCulture
                  When = $Now
               }
      $truth = "@{",
               "  InstallPaths = @{",
               "    CommonPath = '{ProgramFiles}\WindowsPowerShell\Modules'",
               "    UserPath = '{MyDocuments}\WindowsPowerShell\Modules'",
               "  }",
               "  Repositories = @{",
               "    FileSystem = @('\\PoshCode.org\Modules','P:\Modules')",
               "  }",
               "  Custom = PSObject @{",
               "    FirstName = 'Joel'",
               "    LastName = 'Bennett'",
               "    Age = 39",
               "  }",
               "  Guid = Guid '$Guid'",
               "  Culture = '$PSCulture'",
               "  When = DateTime '$($Now.ToString('o'))'",
               "}"
   }
   act {
      $result = ConvertTo-Metadata $table
   }
   assert {
      # It's not that they can be in ANY order, but the values can be
      # This is just simpler than trying to sort only the hashtable content
      $truth = $truth
      $result = ($result -split "[\r\n]+")

      $truth = ($truth | sort) -join "`n"
      $result = ($result | sort) -join "`n"

      $truth.MustEqual($result)
   }
} -Category Serialize

