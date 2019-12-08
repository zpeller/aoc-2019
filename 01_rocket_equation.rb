#!/usr/bin/ruby

require 'pp'

input = (ARGV.empty? ? DATA : ARGF).each_line.map(&:to_i).freeze

# pp input

def fuel_required(mass)
	mass/3 - 2
end

def fuel_required_with_self(mass)
	total_fuel = 0
	loop do
		fuel = fuel_required(mass)
		break total_fuel if fuel <= 0
		total_fuel += fuel
		mass = fuel
	end
end

total_fuel_required = input.inject { |total_fuel, mass| total_fuel + fuel_required(mass) }
print("P1 total fuel required: #{total_fuel_required}\n")

total_fuel_required_with_self = input.inject { |total_fuel, mass| total_fuel + fuel_required_with_self(mass) }
print("P2 total fuel (with self calculated) required: #{total_fuel_required_with_self}\n")

__END__
89122
141123
91549
66506
53504
56517
77050
92298
84853
141828
86739
126125
82793
113761
68961
132576
61718
64498
110415
134867
102449
107364
88491
120584
52192
130494
121583
132166
111339
68715
104966
117227
58921
83909
70626
141637
95127
72029
136121
136915
74312
54863
53547
149493
78528
132289
148754
133905
135357
58483
62214
124684
118590
107087
95768
86835
122277
126183
108546
75212
62280
76039
135743
86133
111613
139477
65930
106225
101531
96501
66844
114158
137091
138143
102083
69857
59372
137605
108135
96365
94851
104414
74194
74188
131888
75910
78279
93285
53597
82705
119360
149274
92510
95490
54087
97695
94753
80493
101173
51906
