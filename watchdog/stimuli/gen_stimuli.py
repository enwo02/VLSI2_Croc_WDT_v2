import random

random.seed(0)  # For reproducibility

# We use 2**3 as max timeout as otherwise the simulation would be way too long for a 32 bit value
# Generate random timeout_i and time at witch kick_i is 1
def generate_test_vectors(filename, num_vectors=100):
  with open(filename, 'w') as f:
    for _ in range(num_vectors):
      timeout_i = random.randint(0, 2**3 - 1)  # 32-bit value
      kick_t = random.randint(0, 2**3 - 1)  # 32-bit value, time at which kisk_i high
      
      binary_string = f"{timeout_i:032b}{kick_t:032b}"
      f.write(binary_string + "\n")

if __name__ == "__main__":
  generate_test_vectors("stimuli.txt", 32)
