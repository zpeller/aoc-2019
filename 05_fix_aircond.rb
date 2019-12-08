#!/usr/bin/ruby

require 'pp'

input = (ARGV.empty? ? DATA : ARGF).each_line.map { |l|
	nums = l.scan(/-?\d+/).map(&:to_i)
}.flatten.freeze

# pp input

DEBUG = false

POSITION_MODE = 0
IMMEDIATE_MODE = 1

class Program
	attr_reader :output_value

	def initialize(program_code, input_value, addr1_val=nil, addr2_val=nil)
		@program_code = program_code.dup
		@instr_ptr = 0
		@input_value = input_value
		@output_value = nil

		set_mem(1, addr1_val) if addr1_val
		set_mem(2, addr2_val) if addr2_val
	end

	def set_mem(addr, value)
		@program_code[addr] = value
	end

	def get_mem(addr)
		return @program_code[addr]
	end

	def set_mem_ptr(addr, value)
		return @program_code[@program_code[addr]] = value
	end

	def get_mem_ptr(addr)
		return @program_code[@program_code[addr]]
	end
	
	def get_from_input
		return @input_value
	end
	
	def send_to_output(value)
		@output_value = value
	end
	
	def decode_instruction(instruction)
		opcode = instruction % 100
		param_modes = sprintf("%03d", instruction/100).chars.map(&:to_i).reverse
		return opcode, param_modes
	end

	def get_param_value(addr_or_value, param_mode)
		case param_mode
		when 1
			return addr_or_value
		when 0
			return get_mem(addr_or_value)
		end
	end

	def run_program
		instr_ptr = 0
		loop do
			opcode, param_modes = decode_instruction(get_mem(instr_ptr))
			case opcode
			when 1
				printf("PC: #{instr_ptr} codes: #{@program_code[instr_ptr..(instr_ptr+3)]} op: #{opcode} mode: #{param_modes}\n") if DEBUG
				set_mem_ptr( instr_ptr+3, get_param_value(get_mem(instr_ptr+1), param_modes[0]) + get_param_value(get_mem(instr_ptr+2), param_modes[1]) )
				instr_ptr += 4

			when 2
				printf("PC: #{instr_ptr} codes: #{@program_code[instr_ptr..(instr_ptr+3)]} op: #{opcode} mode: #{param_modes}\n") if DEBUG
				set_mem_ptr( instr_ptr+3, get_param_value(get_mem(instr_ptr+1), param_modes[0]) * get_param_value(get_mem(instr_ptr+2), param_modes[1]) )
				instr_ptr += 4

			when 3
				printf("PC: #{instr_ptr} codes: #{@program_code[instr_ptr..(instr_ptr+1)]} op: #{opcode} mode: #{param_modes}\n") if DEBUG
				set_mem_ptr(instr_ptr+1, get_from_input())
				instr_ptr += 2

			when 4
				printf("PC: #{instr_ptr} codes: #{@program_code[instr_ptr..(instr_ptr+1)]} op: #{opcode} mode: #{param_modes}\n") if DEBUG
				send_to_output(get_mem_ptr(instr_ptr+1))
				instr_ptr += 2

			when 5..6
				printf("PC: #{instr_ptr} codes: #{@program_code[instr_ptr..(instr_ptr+2)]} op: #{opcode} mode: #{param_modes}\n") if DEBUG
				if (get_param_value(get_mem(instr_ptr+1), param_modes[0]) != 0) ^ (opcode == 6) 
					instr_ptr = get_param_value(get_mem(instr_ptr+2), param_modes[1])
				else
					instr_ptr += 3
				end

			when 7..8
				printf("PC: #{instr_ptr} codes: #{@program_code[instr_ptr..(instr_ptr+3)]} op: #{opcode} mode: #{param_modes}\n") if DEBUG
				v1 = get_param_value(get_mem(instr_ptr+1), param_modes[0]) 
   				v2 = get_param_value(get_mem(instr_ptr+2), param_modes[1])

				if ((opcode == 7) and (v1 < v2)) or
				   ((opcode == 8) and (v1 == v2))
					set_mem_ptr(instr_ptr+3, 1)
				else
					set_mem_ptr(instr_ptr+3, 0)
				end
				instr_ptr += 4

			when 99 
				printf("PC: #{instr_ptr} codes: #{@program_code[instr_ptr]} op: #{opcode} mode: #{param_modes}\n") if DEBUG
				instr_ptr += 1
				break
			else
				printf("PC: #{instr_ptr} codes: #{@program_code[instr_ptr]} op: #{opcode} mode: #{param_modes}\n") if DEBUG
				printf("Invalid instruction #{@program_code[instr_ptr]}\n")
				@output_value = "invalid instruction error"
				break
			end
		end
		return @output_value
	end
end

program = Program.new(input, 1)
program.run_program

printf("P1 diagnostic code: #{program.output_value}\n")

program = Program.new(input, 5)
program.run_program

printf("P2 diagnostic code: #{program.output_value}\n")

__END__
3,225,1,225,6,6,1100,1,238,225,104,0,1102,72,20,224,1001,224,-1440,224,4,224,102,8,223,223,1001,224,5,224,1,224,223,223,1002,147,33,224,101,-3036,224,224,4,224,102,8,223,223,1001,224,5,224,1,224,223,223,1102,32,90,225,101,65,87,224,101,-85,224,224,4,224,1002,223,8,223,101,4,224,224,1,223,224,223,1102,33,92,225,1102,20,52,225,1101,76,89,225,1,117,122,224,101,-78,224,224,4,224,102,8,223,223,101,1,224,224,1,223,224,223,1102,54,22,225,1102,5,24,225,102,50,84,224,101,-4600,224,224,4,224,1002,223,8,223,101,3,224,224,1,223,224,223,1102,92,64,225,1101,42,83,224,101,-125,224,224,4,224,102,8,223,223,101,5,224,224,1,224,223,223,2,58,195,224,1001,224,-6840,224,4,224,102,8,223,223,101,1,224,224,1,223,224,223,1101,76,48,225,1001,92,65,224,1001,224,-154,224,4,224,1002,223,8,223,101,5,224,224,1,223,224,223,4,223,99,0,0,0,677,0,0,0,0,0,0,0,0,0,0,0,1105,0,99999,1105,227,247,1105,1,99999,1005,227,99999,1005,0,256,1105,1,99999,1106,227,99999,1106,0,265,1105,1,99999,1006,0,99999,1006,227,274,1105,1,99999,1105,1,280,1105,1,99999,1,225,225,225,1101,294,0,0,105,1,0,1105,1,99999,1106,0,300,1105,1,99999,1,225,225,225,1101,314,0,0,106,0,0,1105,1,99999,1107,677,226,224,1002,223,2,223,1005,224,329,101,1,223,223,7,677,226,224,102,2,223,223,1005,224,344,1001,223,1,223,1107,226,226,224,1002,223,2,223,1006,224,359,1001,223,1,223,8,226,226,224,1002,223,2,223,1006,224,374,101,1,223,223,108,226,226,224,102,2,223,223,1005,224,389,1001,223,1,223,1008,226,226,224,1002,223,2,223,1005,224,404,101,1,223,223,1107,226,677,224,1002,223,2,223,1006,224,419,101,1,223,223,1008,226,677,224,1002,223,2,223,1006,224,434,101,1,223,223,108,677,677,224,1002,223,2,223,1006,224,449,101,1,223,223,1108,677,226,224,102,2,223,223,1006,224,464,1001,223,1,223,107,677,677,224,102,2,223,223,1005,224,479,101,1,223,223,7,226,677,224,1002,223,2,223,1006,224,494,1001,223,1,223,7,677,677,224,102,2,223,223,1006,224,509,101,1,223,223,107,226,677,224,1002,223,2,223,1006,224,524,1001,223,1,223,1007,226,226,224,102,2,223,223,1006,224,539,1001,223,1,223,108,677,226,224,102,2,223,223,1005,224,554,101,1,223,223,1007,677,677,224,102,2,223,223,1006,224,569,101,1,223,223,8,677,226,224,102,2,223,223,1006,224,584,1001,223,1,223,1008,677,677,224,1002,223,2,223,1006,224,599,1001,223,1,223,1007,677,226,224,1002,223,2,223,1005,224,614,101,1,223,223,1108,226,677,224,1002,223,2,223,1005,224,629,101,1,223,223,1108,677,677,224,1002,223,2,223,1005,224,644,1001,223,1,223,8,226,677,224,1002,223,2,223,1006,224,659,101,1,223,223,107,226,226,224,102,2,223,223,1005,224,674,101,1,223,223,4,223,99,226
