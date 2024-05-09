# <copyright file="ConvertFrom-Fwsv.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

function ConvertFrom-Fwsv {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]    # allow empty lines to be processed
        [string[]]$InputObject,

        [Parameter(Mandatory = $true)]
        [string[]]$Headers
    )

    begin {
        $columnOffsets = @()
        $result = @()
    }
    
    process {
        # When processing via the pipeline, this block will be called for each row
        # so we need to ensure we only calculate the column offsets once
        if ($columnOffsets.Count -eq 0) {
            # Calculate the column offset for each header using the first row
            $headerRow = $InputObject[0]
            foreach ($header in $Headers) {
                $offset = $headerRow.IndexOf($header)
                if ($offset -eq -1) {
                    throw "Header '$header' not found in input data: '$headerRow'"
                }
                $columnOffsets += $offset
            }
            
            # If we are processing via the pipeline then skip the rest of the process block
            # as we don't want to create a row for the column headers
            if ($MyInvocation.ExpectingInput) {
                return
            }
        }

        # Use those offsets to extract the values for each row
        foreach ($row in $InputObject[1..($InputObject.Count-1)]) {
            # Skip empty rows
            if ($row.Length -eq 0) { continue }

            $rowObject = [ordered]@{}
            # Process each column
            foreach ($columnNum in 0..($columnOffsets.Count-1)) {
                $currentColumnOffset = $columnOffsets[$columnNum]
                if ($currentColumnOffset -ge $row.Length) {
                    # We have a truncated row (i.e. the last column is missing)
                    $rowObject[$Headers[$columnNum]] = ''
                }
                else {
                    # Calculate the offset for where the next column starts so we can extract the value of the current column
                    $isLastColumn = $columnNum+1 -ge $columnOffsets.Count
                    if ($isLastColumn) {
                        # If this is the last column, then the 'next column' starts at the end of the row
                        $currentColumnWidth = $row.Length - $currentColumnOffset
                    }
                    else {
                        # Otherwise, it starts at the next column offset or the end of the row if it is truncated (i.e. the last column is missing)
                        $nextColumnOffset = [int]::Min($row.Length, $columnOffsets[$columnNum+1])
                        $currentColumnWidth = $nextColumnOffset - $currentColumnOffset
                    }
                    $rowObject[$Headers[$columnNum]] = $row.SubString($currentColumnOffset, $currentColumnWidth).TrimEnd()
                }
            }
            $result += [pscustomobject]$rowObject
        }
    }
    
    end {
        $result
    }
}