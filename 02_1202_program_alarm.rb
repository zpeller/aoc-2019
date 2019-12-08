#!/usr/bin/ruby

require 'pp'

input = (ARGV.empty? ? DATA : ARGF).each_line.map { |l|
	nums = l.scan(/-?\d+/).map(&:to_i)
}.flatten.freeze

# pp input

def get_val_at_ptr(program, pos)
	return program[program[pos]]
end

def run_program_p1(input, noun, verb)
	prog = input.dup

	prog[1] = noun
	prog[2] = verb

	instr_ptr = 0
	loop do
		case prog[instr_ptr]
		when 1
			prog[prog[instr_ptr+3]] = get_val_at_ptr(prog, instr_ptr+1) + get_val_at_ptr(prog, instr_ptr+2)
		when 2
			prog[prog[instr_ptr+3]] = get_val_at_ptr(prog, instr_ptr+1) * get_val_at_ptr(prog, instr_ptr+2)
		when 99 
			break
		end
		instr_ptr += 4
	end
	return prog[0]
end

def find_target(input, target_value)
	(0..99).each { |noun|
		(0..99).each { |verb|
			return noun*100 + verb if run_program_p1(input, noun, verb) == target_value
		}
	}
	return nil
end

printf("P1 value at pos 0: #{run_program_p1(input, 12, 2)}\n")

target_value = 19690720
printf("P2 noun*100+verb: #{find_target(input, target_value)}\n")


__END__
1,0,0,3,1,1,2,3,1,3,4,3,1,5,0,3,2,1,13,19,1,10,19,23,2,9,23,27,1,6,27,31,1,10,31,35,1,35,10,39,1,9,39,43,1,6,43,47,1,10,47,51,1,6,51,55,2,13,55,59,1,6,59,63,1,10,63,67,2,67,9,71,1,71,5,75,1,13,75,79,2,79,13,83,1,83,9,87,2,10,87,91,2,91,6,95,2,13,95,99,1,10,99,103,2,9,103,107,1,107,5,111,2,9,111,115,1,5,115,119,1,9,119,123,2,123,6,127,1,5,127,131,1,10,131,135,1,135,6,139,1,139,5,143,1,143,9,147,1,5,147,151,1,151,13,155,1,5,155,159,1,2,159,163,1,163,6,0,99,2,0,14,0
