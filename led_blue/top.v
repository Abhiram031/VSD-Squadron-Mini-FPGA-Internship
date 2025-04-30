//-----------------------------------------------------------------------------
// File: top.v
// Description: Top-level module for VSDSquadron FPGA Mini Board
// - Drives the onboard RGB LEDs using an internal oscillator and a counter
// Date: April 2025
//-----------------------------------------------------------------------------

module top (
  // Outputs
  output wire led_red,    // Red LED output control
  output wire led_blue,   // Blue LED output control
  output wire led_green,  // Green LED output control
  output wire testwire,   // Test output signal (from counter)

  // Inputs
  input  wire hw_clk      // External oscillator input (provided but not used internally)
);

  wire        int_osc;             // Internal oscillator output
  reg  [27:0] frequency_counter_i; // 28-bit counter driven by internal oscillator

  //-------------------------------------------------------------------------------
  //          Testwire Output Assignment
  // Assigns a slower toggling signal from the 25th bit of the counter
  // (i.e., frequency_counter_i[24]) to the testwire output.
  //-------------------------------------------------------------------------------
  assign testwire = frequency_counter_i[24];

  //-------------------------------------------------------------------------------
  //                      Frequency Counter Logic
  // Increments the counter at each positive edge of the internal oscillator clock
  //-------------------------------------------------------------------------------
  always @(posedge int_osc) begin
    frequency_counter_i <= frequency_counter_i + 1'b1;
  end

  //-------------------------------------------------------------------------------
  // Internal Oscillator Instantiation
  // Using SB_HFOSC primitive to generate an internal clock
  // CLKHF_DIV set to "0b10" for frequency division
  //-------------------------------------------------------------------------------
  SB_HFOSC #(
    .CLKHF_DIV("0b10") // Divide internal oscillator frequency
  ) u_SB_HFOSC (
    .CLKHFPU(1'b1),    // Power up internal oscillator
    .CLKHFEN(1'b1),    // Enable internal oscillator
    .CLKHF(int_osc)    // Output clock signal
  );

  //-------------------------------------------------------------------------------
  // RGB LED Driver Instantiation
  // Using SB_RGBA_DRV primitive to drive the onboard RGB LEDs
  // Configured with minimal current settings
  //-------------------------------------------------------------------------------
  SB_RGBA_DRV RGB_DRIVER (
    .RGBLEDEN(1'b1),    // Enable RGB output
    .RGB0PWM (1'b0),    // PWM control for Red LED (off)
    .RGB1PWM (1'b0),    // PWM control for Green LED (off)
    .RGB2PWM (testwire),    // PWM control for Blue LED (on)
    .CURREN  (1'b1),    // Enable current to RGB pins
    .RGB0    (led_red),   // Connect Red output to physical pin
    .RGB1    (led_green), // Connect Green output to physical pin
    .RGB2    (led_blue)   // Connect Blue output to physical pin
  );

  // Set current drive strengths (minimal values)
  defparam RGB_DRIVER.RGB0_CURRENT = "0b000001"; // Red LED current
  defparam RGB_DRIVER.RGB1_CURRENT = "0b000001"; // Green LED current
  defparam RGB_DRIVER.RGB2_CURRENT = "0b000001"; // Blue LED current

endmodule
