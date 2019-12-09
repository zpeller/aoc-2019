#!/usr/bin/ruby

require 'pp'

input = (ARGV.empty? ? DATA : ARGF).each_line.map { |l|
	nums = l.scan(/-?\d+/).map(&:to_i)
}.flatten.freeze

# pp input

memory = Hash.new(0)
input.each_with_index { |n, idx| memory[idx] = n }

DEBUG = false

POSITION_MODE = 0
IMMEDIATE_MODE = 1
RELATIVE_MODE = 2

OP_ADD = 1
OP_MUL = 2
OP_GET_INPUT = 3
OP_SEND_OUTPUT = 4
OP_JNZ = 5
OP_JZ = 6
OP_TEST_LT = 7
OP_TEST_EQ = 8
OP_ADJ_RELBASE = 9
OP_HALT = 99

class Program
	attr_reader :output_value, :program_state

	def initialize(program_code, addr1_val=nil, addr2_val=nil)
		@program_code = program_code.dup
		@program_state = "suspended"
		@instr_ptr = 0
		@program_counter = 0
		@relative_base = 0
		@input_queue = []
		@output_value = nil
		@output_program = nil

		set_mem_direct(1, addr1_val) if addr1_val
		set_mem_direct(2, addr2_val) if addr2_val
	end

	def set_mem_direct(addr, value)
		@program_code[addr] = value
	end

	def get_mem(addr)
		return @program_code[addr]
	end

	def set_mem_ptr(addr, value)
		@program_code[@program_code[addr]] = value
	end

	def set_mem_relative(addr, value)
		@program_code[@relative_base + @program_code[addr]] = value
	end

	def set_mem(addr, value, mode)
		case mode
		when POSITION_MODE
			set_mem_ptr(addr, value)
		when IMMEDIATE_MODE
			set_mem_direct(addr, value)
		when RELATIVE_MODE
			set_mem_relative(addr, value)
		end
	end

	def get_mem_ptr(addr)
		return @program_code[@program_code[addr]]
	end
	
	def add_input(value)
		@input_queue << value
	end

	def get_from_input
		return @input_queue.shift
	end
	
	def set_output_program(program)
		@output_program = program
	end

	def send_to_output(value)
		@output_value = value
		@output_program.add_input(value) if not @output_program.nil?
	end
	
	def decode_instruction(instruction)
		opcode = instruction % 100
		param_modes = sprintf("%03d", instruction/100).chars.map(&:to_i).reverse
		return opcode, param_modes
	end

	def get_param_value(addr_or_value, param_mode)
		case param_mode
		when POSITION_MODE
			return get_mem(addr_or_value)
		when IMMEDIATE_MODE
			return addr_or_value
		when RELATIVE_MODE
			return get_mem(@relative_base + addr_or_value)
		end
	end

	def run_program
		return -1 if @program_state == "halted"
		@program_state = "running"
		loop do
			opcode, param_modes = decode_instruction(get_mem(@instr_ptr))
			@program_counter += 1
			printf("PC: #{@program_counter} IC: #{@instr_ptr} codes: #{@program_code[@instr_ptr]} #{@program_code[@instr_ptr+1]} #{@program_code[@instr_ptr+2]} #{@program_code[@instr_ptr+3]}  op: #{opcode} mode: #{param_modes}\n") if DEBUG

			case opcode
			when OP_ADD
				set_mem( @instr_ptr+3, get_param_value(get_mem(@instr_ptr+1), param_modes[0]) + get_param_value(get_mem(@instr_ptr+2), param_modes[1]), param_modes[2] )
				@instr_ptr += 4

			when OP_MUL
				set_mem( @instr_ptr+3, get_param_value(get_mem(@instr_ptr+1), param_modes[0]) * get_param_value(get_mem(@instr_ptr+2), param_modes[1]), param_modes[2] )
				@instr_ptr += 4

			when OP_GET_INPUT
				if @input_queue.length == 0
					@program_state = "suspended"
					return -1
				end
				set_mem(@instr_ptr+1, get_from_input(), param_modes[0])
				@instr_ptr += 2

			when OP_SEND_OUTPUT
#				send_to_output(get_mem_ptr(@instr_ptr+1))
				send_to_output(get_param_value(get_mem(@instr_ptr+1), param_modes[0]))
				@instr_ptr += 2

			when OP_JNZ, OP_JZ
				if (get_param_value(get_mem(@instr_ptr+1), param_modes[0]) != 0) ^ (opcode == OP_JZ) 
					@instr_ptr = get_param_value(get_mem(@instr_ptr+2), param_modes[1])
				else
					@instr_ptr += 3
				end

			when OP_TEST_LT, OP_TEST_EQ
				v1 = get_param_value(get_mem(@instr_ptr+1), param_modes[0]) 
   				v2 = get_param_value(get_mem(@instr_ptr+2), param_modes[1])

				if ((opcode == OP_TEST_LT) and (v1 < v2)) or
				   ((opcode == OP_TEST_EQ) and (v1 == v2))
					set_mem(@instr_ptr+3, 1, param_modes[2])
				else
					set_mem(@instr_ptr+3, 0, param_modes[2])
				end
				@instr_ptr += 4

			when OP_ADJ_RELBASE
				@relative_base += get_param_value(get_mem(@instr_ptr+1), param_modes[0])
				@instr_ptr += 2

			when OP_HALT
				@program_state = "halted"
				@instr_ptr += 1
				break

			else
				printf("Invalid instruction #{@program_code[@instr_ptr]}\n")
				@output_value = "invalid instruction error"
				@program_state = "halted"
				break
			end
		end
		return @output_value
	end
end

def test_boost(program_code, input_value)
	program = Program.new(program_code)
	program.add_input(input_value)
	program.run_program
	return program.output_value
end

# pp memory
printf("P1 BOOST code: #{test_boost(memory, 1)}\n")
printf("P2 coordinates: #{test_boost(memory, 2)}\n")

__END__
1102,34463338,34463338,63,1007,63,34463338,63,1005,63,53,1102,3,1,1000,109,988,209,12,9,1000,209,6,209,3,203,0,1008,1000,1,63,1005,63,65,1008,1000,2,63,1005,63,904,1008,1000,0,63,1005,63,58,4,25,104,0,99,4,0,104,0,99,4,17,104,0,99,0,0,1102,0,1,1020,1102,1,38,1015,1102,37,1,1003,1102,21,1,1002,1102,34,1,1017,1101,39,0,1008,1102,1,20,1007,1101,851,0,1022,1102,1,1,1021,1101,24,0,1009,1101,0,26,1005,1101,29,0,1019,1101,0,866,1027,1101,0,260,1025,1102,33,1,1014,1101,0,36,1006,1102,1,25,1018,1102,1,669,1028,1101,0,27,1016,1101,0,23,1012,1102,35,1,1004,1102,1,31,1011,1101,0,664,1029,1101,32,0,1010,1101,0,22,1000,1102,873,1,1026,1102,1,848,1023,1102,265,1,1024,1101,0,28,1013,1101,30,0,1001,109,6,2107,31,-5,63,1005,63,201,1001,64,1,64,1106,0,203,4,187,1002,64,2,64,109,4,21107,40,39,1,1005,1011,219,1106,0,225,4,209,1001,64,1,64,1002,64,2,64,109,-1,2102,1,0,63,1008,63,24,63,1005,63,247,4,231,1106,0,251,1001,64,1,64,1002,64,2,64,109,9,2105,1,6,4,257,1105,1,269,1001,64,1,64,1002,64,2,64,109,-18,2108,19,2,63,1005,63,289,1001,64,1,64,1106,0,291,4,275,1002,64,2,64,109,23,21108,41,41,-8,1005,1015,313,4,297,1001,64,1,64,1106,0,313,1002,64,2,64,109,-19,2101,0,-4,63,1008,63,23,63,1005,63,333,1106,0,339,4,319,1001,64,1,64,1002,64,2,64,109,9,1206,7,357,4,345,1001,64,1,64,1105,1,357,1002,64,2,64,109,-15,2108,22,2,63,1005,63,375,4,363,1105,1,379,1001,64,1,64,1002,64,2,64,109,10,1208,-7,30,63,1005,63,397,4,385,1106,0,401,1001,64,1,64,1002,64,2,64,109,-7,1201,8,0,63,1008,63,27,63,1005,63,421,1106,0,427,4,407,1001,64,1,64,1002,64,2,64,109,-4,1202,3,1,63,1008,63,22,63,1005,63,449,4,433,1105,1,453,1001,64,1,64,1002,64,2,64,109,15,21108,42,40,4,1005,1016,469,1105,1,475,4,459,1001,64,1,64,1002,64,2,64,109,1,21101,43,0,0,1008,1013,43,63,1005,63,501,4,481,1001,64,1,64,1105,1,501,1002,64,2,64,109,-17,1207,10,35,63,1005,63,521,1001,64,1,64,1105,1,523,4,507,1002,64,2,64,109,7,2107,23,6,63,1005,63,545,4,529,1001,64,1,64,1105,1,545,1002,64,2,64,109,3,1201,0,0,63,1008,63,36,63,1005,63,571,4,551,1001,64,1,64,1105,1,571,1002,64,2,64,109,1,21107,44,45,7,1005,1014,593,4,577,1001,64,1,64,1106,0,593,1002,64,2,64,109,7,1205,6,609,1001,64,1,64,1106,0,611,4,599,1002,64,2,64,109,-14,1202,4,1,63,1008,63,32,63,1005,63,635,1001,64,1,64,1106,0,637,4,617,1002,64,2,64,109,30,1205,-9,651,4,643,1105,1,655,1001,64,1,64,1002,64,2,64,109,-4,2106,0,2,4,661,1106,0,673,1001,64,1,64,1002,64,2,64,109,-5,21101,45,0,-8,1008,1013,42,63,1005,63,697,1001,64,1,64,1106,0,699,4,679,1002,64,2,64,109,-10,1207,-6,27,63,1005,63,721,4,705,1001,64,1,64,1105,1,721,1002,64,2,64,109,-11,2101,0,6,63,1008,63,36,63,1005,63,743,4,727,1106,0,747,1001,64,1,64,1002,64,2,64,109,3,2102,1,-2,63,1008,63,33,63,1005,63,767,1105,1,773,4,753,1001,64,1,64,1002,64,2,64,109,18,1206,0,789,1001,64,1,64,1106,0,791,4,779,1002,64,2,64,109,-11,1208,-5,23,63,1005,63,807,1106,0,813,4,797,1001,64,1,64,1002,64,2,64,109,-5,21102,46,1,10,1008,1015,46,63,1005,63,835,4,819,1105,1,839,1001,64,1,64,1002,64,2,64,109,11,2105,1,7,1106,0,857,4,845,1001,64,1,64,1002,64,2,64,109,14,2106,0,-3,1001,64,1,64,1106,0,875,4,863,1002,64,2,64,109,-22,21102,47,1,5,1008,1013,48,63,1005,63,899,1001,64,1,64,1106,0,901,4,881,4,64,99,21102,1,27,1,21102,915,1,0,1105,1,922,21201,1,65718,1,204,1,99,109,3,1207,-2,3,63,1005,63,964,21201,-2,-1,1,21102,1,942,0,1105,1,922,22101,0,1,-1,21201,-2,-3,1,21102,957,1,0,1106,0,922,22201,1,-1,-2,1105,1,968,21201,-2,0,-2,109,-3,2105,1,0
