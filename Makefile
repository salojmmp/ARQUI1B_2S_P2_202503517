# MiniShell ARM64 - Makefile
# Ensamblador GAS para Linux ARM64

AS = aarch64-linux-gnu-as
LD = aarch64-linux-gnu-ld

SRC_DIR = src
BUILD_DIR = build

TARGET = minishell
OBJECTS = $(BUILD_DIR)/main.o

ASFLAGS = -g

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(LD) -o $@ $(OBJECTS)

$(BUILD_DIR)/main.o: $(SRC_DIR)/main.s
	mkdir -p $(BUILD_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -rf $(BUILD_DIR) $(TARGET)
