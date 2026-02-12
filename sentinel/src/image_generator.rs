use std::time::{SystemTime, UNIX_EPOCH};

/// Generates a smooth, non-flickering random image at 16:9 aspect ratio
/// Returns (width, height, raw_rgba_data)
pub fn generate_random_image(width: usize) -> (usize, usize, Vec<u8>) {
    let height = (width * 9) / 16;
    let mut raw = vec![0u8; width * height * 4];

    // Get current time in milliseconds for seeding and display
    let time_ms = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis() as u64;

    // Use time to seed our fast random pattern
    // We divide by 200ms to get smooth transitions (5 updates per second)
    let seed = (time_ms / 200) as u32;

    // Fast pseudo-random number generator (xorshift32)
    let mut rng_state = seed.wrapping_mul(747796405).wrapping_add(2891336453);

    #[inline]
    fn next_random(state: &mut u32) -> u32 {
        *state ^= *state << 13;
        *state ^= *state >> 17;
        *state ^= *state << 5;
        *state
    }

    // Generate smooth gradient-based pattern with slow-moving noise
    // This prevents flickering and is comfortable to watch
    let phase = (time_ms as f32 / 3000.0) % (2.0 * std::f32::consts::PI);

    // Create DARK, muted color waves - much more comfortable for big screens
    // Range: 20-60 instead of 80-180 (way darker)
    let base_r = ((phase.sin() * 0.5 + 0.5) * 25.0 + 25.0) as u8;
    let base_g = (((phase + 2.0).sin() * 0.5 + 0.5) * 25.0 + 25.0) as u8;
    let base_b = (((phase + 4.0).sin() * 0.5 + 0.5) * 25.0 + 25.0) as u8;

    // Generate pixel data with smooth noise
    for y in 0..height {
        for x in 0..width {
            let idx = (y * width + x) * 4;

            // Create smooth spatial variation
            let nx = x as f32 / width as f32;
            let ny = y as f32 / height as f32;

            // Fast pseudo-random variation (very small range for smooth, dark look)
            let rand_val = next_random(&mut rng_state);
            let noise = ((rand_val % 20) as i16) - 10; // -10 to +10 variation

            // Very subtle gradient (keeping things dark)
            let grad = ((nx * 0.2 + ny * 0.3) * 20.0) as i16;

            raw[idx] = (base_r as i16 + grad + noise).clamp(0, 255) as u8;
            raw[idx + 1] = (base_g as i16 + grad + (noise / 2)).clamp(0, 255) as u8;
            raw[idx + 2] = (base_b as i16 + grad + (noise / 3)).clamp(0, 255) as u8;
            raw[idx + 3] = 255; // Alpha
        }
    }

    // Encode time as pixels in top-left corner (64x8 pixel clock display)
    // This creates a visual "digital clock" effect
    encode_time_pixels(&mut raw, width, time_ms);

    (width, height, raw)
}

/// Encodes time as visible pixels in the top-left corner
fn encode_time_pixels(raw: &mut [u8], width: usize, time_ms: u64) {
    let seconds = (time_ms / 1000) % 60;
    let minutes = (time_ms / 60000) % 60;
    let hours = (time_ms / 3600000) % 24;

    // Simple 5x7 digit patterns (just showing segments for readability)
    let draw_digit =
        |raw: &mut [u8], width: usize, x_offset: usize, y_offset: usize, digit: u64| {
            // Simple bar pattern representing the digit (0-9)
            let patterns = [
                0b11111101, // 0
                0b01100000, // 1
                0b11011011, // 2
                0b11110011, // 3
                0b01100111, // 4
                0b10110111, // 5
                0b10111111, // 6
                0b11100000, // 7
                0b11111111, // 8
                0b11110111, // 9
            ];

            let pattern = patterns[digit as usize % 10];

            // Draw 7-segment-style digit (simplified)
            for dy in 0..7 {
                for dx in 0..5 {
                    let px = x_offset + dx;
                    let py = y_offset + dy;
                    let idx = (py * width + px) * 4;

                    let bit_set = match (dx, dy) {
                        (1..=3, 0) => pattern & 0b10000000 != 0, // top
                        (4, 1..=2) => pattern & 0b01000000 != 0, // top-right
                        (4, 4..=5) => pattern & 0b00100000 != 0, // bottom-right
                        (1..=3, 6) => pattern & 0b00010000 != 0, // bottom
                        (0, 4..=5) => pattern & 0b00001000 != 0, // bottom-left
                        (0, 1..=2) => pattern & 0b00000100 != 0, // top-left
                        (1..=3, 3) => pattern & 0b00000010 != 0, // middle
                        _ => false,
                    };

                    if bit_set {
                        raw[idx] = 80; // R - much dimmer
                        raw[idx + 1] = 80; // G
                        raw[idx + 2] = 80; // B
                        raw[idx + 3] = 255; // A
                    }
                }
            }
        };

    // Helper to draw a colon (two dots)
    let draw_colon = |raw: &mut [u8], width: usize, x: usize, y: usize| {
        // Top dot
        for dy in 0..2 {
            for dx in 0..2 {
                let idx = ((y + 2 + dy) * width + x + dx) * 4;
                raw[idx] = 80;
                raw[idx + 1] = 80;
                raw[idx + 2] = 80;
                raw[idx + 3] = 255;
            }
        }
        // Bottom dot
        for dy in 0..2 {
            for dx in 0..2 {
                let idx = ((y + 5 + dy) * width + x + dx) * 4;
                raw[idx] = 80;
                raw[idx + 1] = 80;
                raw[idx + 2] = 80;
                raw[idx + 3] = 255;
            }
        }
    };

    // Draw HH:MM:SS in top-left
    let spacing = 8;
    draw_digit(raw, width, 2, 2, hours / 10);
    draw_digit(raw, width, 2 + spacing, 2, hours % 10);

    // Colon
    draw_colon(raw, width, 2 + spacing * 2 + 2, 2);

    draw_digit(raw, width, 2 + spacing * 3, 2, minutes / 10);
    draw_digit(raw, width, 2 + spacing * 4, 2, minutes % 10);

    // Colon
    draw_colon(raw, width, 2 + spacing * 5 + 2, 2);

    draw_digit(raw, width, 2 + spacing * 6, 2, seconds / 10);
    draw_digit(raw, width, 2 + spacing * 7, 2, seconds % 10);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generates_correct_dimensions() {
        let (w, h, raw) = generate_random_image(1920);
        assert_eq!(w, 1920);
        assert_eq!(h, 1080);
        assert_eq!(raw.len(), 1920 * 1080 * 4);
    }

    #[test]
    fn test_different_calls_produce_different_images() {
        let (_, _, raw1) = generate_random_image(640);
        std::thread::sleep(std::time::Duration::from_millis(210)); // > 200ms
        let (_, _, raw2) = generate_random_image(640);
        assert_ne!(raw1, raw2);
    }
}

// Example usage
fn main() {
    // Generate a 1920x1080 image (16:9)
    let (width, height, raw_data) = generate_random_image(1920);

    println!("Generated image: {}x{}", width, height);
    println!("Data size: {} bytes", raw_data.len());
    println!("First few RGBA values: {:?}", &raw_data[..16]);
}
