def compute_expected_results(input_filename, output_filename):
    with open(input_filename, 'r') as infile, open(output_filename, 'w') as outfile:
        for line in infile:
            # Read timeout_i and kick_t from the file
            timeout_i = int(line[:32], 2)
            print(f"timeout_i: {timeout_i}")
            kick_t = int(line[32:64], 2)
            print(f"kick_t: {kick_t}")
            # Calculate the correct results
            syst_rst_o = (kick_t > timeout_i)
            print(f"syst_rst_o: {syst_rst_o}")
            # Write into syst_rst_o and time it appears
            if syst_rst_o:
                syst_rst_t = timeout_i #+ 1
            else:
                syst_rst_t = kick_t

            print(f"syst_rst_t: {syst_rst_t}")
            # Convert to int to binary
            syst_rst_t = f"{syst_rst_t:032b}" 
            print(f"syst_rst_t: {syst_rst_t}")
            syst_rst_o = f"{syst_rst_o:01b}"
            print(f"syst_rst_o: {syst_rst_o}")
            # Write to the file
            outfile.write(syst_rst_o + syst_rst_t + "\n")

if __name__ == "__main__":
  compute_expected_results("stimuli.txt", "expected_response.txt")
  
