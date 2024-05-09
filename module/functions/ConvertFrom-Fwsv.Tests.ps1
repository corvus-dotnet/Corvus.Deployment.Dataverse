Set-StrictMode -Version Latest

BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
}

Describe 'ConvertFrom-Fwsv' {
    It 'Converts a single row correctly' {
        $data = @(
            'ColA   ColB    ColC'
            'a      b       c'
        )
        $headers = 'ColA', 'ColB', 'ColC'
        $result = ConvertFrom-Fwsv -InputObject $data -Headers $headers
        $result.ColA | Should -Be 'a'
        $result.ColB | Should -Be 'b'
        $result.ColC | Should -Be 'c'
    }

    It 'Converts multiple rows correctly' {
        $data = @(
            'ColA   ColB    ColC'
            'a      b       c'
            'd      e       f'
        )
        $headers = 'ColA', 'ColB', 'ColC'
        $result = ConvertFrom-Fwsv -InputObject $data -Headers $headers
        $result[0].ColA | Should -Be 'a'
        $result[0].ColB | Should -Be 'b'
        $result[0].ColC | Should -Be 'c'
        $result[1].ColA | Should -Be 'd'
        $result[1].ColB | Should -Be 'e'
        $result[1].ColC | Should -Be 'f'
    }

    It 'Handles missing values correctly' {
        $data = @(
            'ColA   ColB    ColC'
            'a              c'
        )
        $headers = 'ColA', 'ColB', 'ColC'
        $result = ConvertFrom-Fwsv -InputObject $data -Headers $headers
        $result.ColA | Should -Be 'a'
        $result.ColB | Should -Be ''
        $result.ColC | Should -Be 'c'
    }

    It 'Handles values with spaces correctly' {
        $data = @(
            'ColA   ColB     ColC'
            'a      foo bar  c'
        )
        $headers = 'ColA', 'ColB', 'ColC'
        $result = ConvertFrom-Fwsv -InputObject $data -Headers $headers
        $result.ColA | Should -Be 'a'
        $result.ColB | Should -Be 'foo bar'
        $result.ColC | Should -Be 'c'
    }

    It 'Handles trucated row correctly' {
        $data = @(
            'ColA   ColB     ColC'
            'a      b'
        )
        $headers = 'ColA', 'ColB', 'ColC'
        $result = ConvertFrom-Fwsv -InputObject $data -Headers $headers
        $result.ColA | Should -Be 'a'
        $result.ColB | Should -Be 'b'
        $result.ColC | Should -Be ''
    }

    It 'Converts a column names with spaces correctly' {
        $data = @(
            'Col A   Col B    Col C'
            'a       b        c'
        )
        $headers = 'Col A', 'Col B', 'Col C'
        $result = ConvertFrom-Fwsv -InputObject $data -Headers $headers
        $result."Col A" | Should -Be 'a'
        $result."Col B" | Should -Be 'b'
        $result."Col C" | Should -Be 'c'
    }
    It 'Handles blank rows correctly' {
        $data = @(
            'ColA   ColB     ColC'
            'a      b'
            ''
            '       e        f'
        )
        $headers = 'ColA', 'ColB', 'ColC'
        $result = ConvertFrom-Fwsv -InputObject $data -Headers $headers
        $result.Count | Should -Be 2
        $result[0].ColA | Should -Be 'a'
        $result[0].ColB | Should -Be 'b'
        $result[0].ColC | Should -Be ''
        $result[1].ColA | Should -Be ''
        $result[1].ColB | Should -Be 'e'
        $result[1].ColC | Should -Be 'f'
    }
    It 'Converts multiple rows correctly via pipeline input' {
        $data = @(
            'ColA   ColB    ColC'
            'a      b       c'
            'd      e       f'
        )
        $headers = 'ColA', 'ColB', 'ColC'
        $result = $data | ConvertFrom-Fwsv -Headers $headers
        $result[0].ColA | Should -Be 'a'
        $result[0].ColB | Should -Be 'b'
        $result[0].ColC | Should -Be 'c'
        $result[1].ColA | Should -Be 'd'
        $result[1].ColB | Should -Be 'e'
        $result[1].ColC | Should -Be 'f'
    }
}