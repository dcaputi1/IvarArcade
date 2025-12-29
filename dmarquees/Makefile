# Makefile for dmarquees
# Marquee display daemon

# Compiler
CC = gcc

# Target executable
TARGET = dmarquees

# Source files
SRCS = dmarquees.c helpers.c

# Compiler and linker flags
CFLAGS = -Wall -O2 $(shell pkg-config --cflags libdrm)
LDFLAGS = $(shell pkg-config --libs libdrm) -lpng

# Default build
all: $(TARGET)

# Compile object file
%.o: %.c
	@echo "Compiling $<..."
	@$(CC) $(CFLAGS) -c $< -o $@

# Link executable
$(TARGET): $(SRCS:.c=.o)
	@echo "Linking $@..."
	@$(CC) -o $@ $^ $(LDFLAGS)
	@echo "Built: $(TARGET)"

# Clean build artifacts
clean:
	@echo "Cleaning dmarquees build artifacts..."
	@rm -f $(TARGET) *.o

.PHONY: all clean
