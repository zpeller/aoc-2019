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
	attr_reader :output_value, :program_state

	def initialize(program_code, addr1_val=nil, addr2_val=nil)
		@program_code = program_code.dup
		@program_state = "suspended"
		@instr_ptr = 0
		@input_queue = []
		@output_value = nil
		@output_program = nil

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
		when 1
			return addr_or_value
		when 0
			return get_mem(addr_or_value)
		end
	end

	def run_program
		return -1 if @program_state == "halted"
		@program_state = "running"
		loop do
			opcode, param_modes = decode_instruction(get_mem(@instr_ptr))
			printf("PC: #{@instr_ptr} codes: #{@program_code[@instr_ptr..(@instr_ptr+3)]} op: #{opcode} mode: #{param_modes}\n") if DEBUG

			case opcode
			when 1
				set_mem_ptr( @instr_ptr+3, get_param_value(get_mem(@instr_ptr+1), param_modes[0]) + get_param_value(get_mem(@instr_ptr+2), param_modes[1]) )
				@instr_ptr += 4

			when 2
				set_mem_ptr( @instr_ptr+3, get_param_value(get_mem(@instr_ptr+1), param_modes[0]) * get_param_value(get_mem(@instr_ptr+2), param_modes[1]) )
				@instr_ptr += 4

			when 3
				if @input_queue.length == 0
					@program_state = "suspended"
					return -1
				end
				set_mem_ptr(@instr_ptr+1, get_from_input())
				@instr_ptr += 2

			when 4
				send_to_output(get_mem_ptr(@instr_ptr+1))
				@instr_ptr += 2

			when 5..6
				if (get_param_value(get_mem(@instr_ptr+1), param_modes[0]) != 0) ^ (opcode == 6) 
					@instr_ptr = get_param_value(get_mem(@instr_ptr+2), param_modes[1])
				else
					@instr_ptr += 3
				end

			when 7..8
				v1 = get_param_value(get_mem(@instr_ptr+1), param_modes[0]) 
   				v2 = get_param_value(get_mem(@instr_ptr+2), param_modes[1])

				if ((opcode == 7) and (v1 < v2)) or
				   ((opcode == 8) and (v1 == v2))
					set_mem_ptr(@instr_ptr+3, 1)
				else
					set_mem_ptr(@instr_ptr+3, 0)
				end
				@instr_ptr += 4

			when 99 
				@instr_ptr += 1
				@program_state = "halted"
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

def get_thruster_value(program_code, phase_settings)
	signal = 0
	(0..4).each { |amp_idx| 
		program = Program.new(program_code)
		program.add_input(phase_settings[amp_idx])
		program.add_input(signal)
		program.run_program
		signal = program.output_value
	}
	return signal
end

def get_max_thruster_value(program_code)
	max_value = 0
	(0..4).to_a.permutation.each {|phase_set|
		max_value = [max_value, get_thruster_value(program_code, phase_set)].max
	}
	return max_value
end

def get_feedback_thruster_value(program_code, phase_settings)
	programs = []
	phase_settings.each { |phase_value| 
		program = Program.new(program_code)
		program.add_input(phase_value)
		programs << program
	}
	
	[0, 1, 2, 3, 4, 0].each_cons(2) { |p1, p2| 
		programs[p1].set_output_program(programs[p2])
	}

	programs[0].add_input(0)

	loop do
		programs.each { |p|
			p.run_program
		}
		break if programs.all? { |p| p.program_state == "halted" }
	end
	return programs[4].output_value
end

def get_max_feedback_thruster_value(program_code)
	max_value = 0
	(5..9).to_a.permutation.each {|phase_set|
		max_value = [max_value, get_feedback_thruster_value(program_code, phase_set)].max
	}
	return max_value
end

printf("P1 max thruster: #{get_max_thruster_value(input)}\n")
printf("P2 max feedback thruster: #{get_max_feedback_thruster_value(input)}\n")


__END__
3,8,1001,8,10,8,105,1,0,0,21,42,55,64,77,94,175,256,337,418,99999,3,9,102,4,9,9,1001,9,5,9,102,2,9,9,101,3,9,9,4,9,99,3,9,102,2,9,9,101,5,9,9,4,9,99,3,9,1002,9,4,9,4,9,99,3,9,102,4,9,9,101,5,9,9,4,9,99,3,9,102,5,9,9,1001,9,3,9,1002,9,5,9,4,9,99,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,99,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,1,9,4,9,99,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,99,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,99,3,9,1001,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,99
