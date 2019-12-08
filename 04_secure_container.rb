#!/usr/bin/ruby

input= [197487,673251].freeze

def is_valid_password(password)
	return ( 
			(password =~ /(.)\1/) and
			(password.chars.sort.join == password)
		   )
end

def is_valid_password_without_triple(password)
	return ( 
			(password.gsub(/(.)\1\1+/, '') =~ /(.)\1/) and
			(password.chars.sort.join == password)
		   )
end

def count_valid_passwords(lower, upper, three_check=false)
	(lower..upper).select { |n|
		if three_check
			is_valid_password_without_triple(n.to_s)
		else
			is_valid_password(n.to_s)
		end
	}.count
end

printf("P1 num valid passwords: #{count_valid_passwords(input[0], input[1])}\n")
printf("P2 num valid passwords: #{count_valid_passwords(input[0], input[1], true)}\n")

