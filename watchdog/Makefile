all: stimuli/stimuli.txt stimuli/expected_response.txt run_sim

stimuli/stimuli.txt: stimuli/gen_stimuli.py
	cd stimuli && python3 gen_stimuli.py

stimuli/expected_response.txt: stimuli/gen_exp_response.py
	cd stimuli && python3 gen_exp_response.py

obj_dir/Vtb_watchdog: sourcecode/watchdog.sv sourcecode/tb_watchdog.sv
	verilator sourcecode/watchdog.sv sourcecode/tb_watchdog.sv \
	  --top tb_watchdog --binary -Wno-fatal --trace --trace-structs --debug --gdbbt

run_sim: obj_dir/Vtb_watchdog
	./obj_dir/Vtb_watchdog

