.equ USE_TEST_DATA, 0


.if USE_TEST_DATA

.equ day11_data_width, 10
.equ day11_data_height, 10
day11_data_start:
.string "5483143223"
.string "2745854711"
.string "5264556173"
.string "6141336146"
.string "6357385478"
.string "4167524645"
.string "2176841721"
.string "6882881134"
.string "4846848554"
.string "5283751526"
day11_data_end:

.else

.equ day11_data_width, 10
.equ day11_data_height, 10
day11_data_start:
.string "1553421288"
.string "5255384882"
.string "1224315732"
.string "4258242274"
.string "1658564216"
.string "6872651182"
.string "5775552238"
.string "5622545172"
.string "8766672318"
.string "2178374835"
day11_data_end:

.endif
