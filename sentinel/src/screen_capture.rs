use base64::Engine;
use xcap::{
    Monitor,
    image::{ExtendedColorType, ImageBuffer, ImageEncoder, Rgba, codecs::png::PngEncoder},
};

type OurImage = ImageBuffer<Rgba<u8>, Vec<u8>>;

pub(crate) fn get_monitor() -> Monitor {
    Monitor::from_point(100, 100).unwrap()
}

pub(crate) fn get_screenshot(monitor: &Monitor) -> OurImage {
    monitor.capture_image().unwrap()
}

pub(crate) fn img_to_png_base64(img: OurImage) -> String {
    let (w, h) = img.dimensions();
    let raw = img.as_raw();

    let mut out = Vec::new();
    let _ = PngEncoder::new(&mut out)
        .write_image(raw, h, w, ExtendedColorType::Rgb8)
        .unwrap();

    base64::engine::general_purpose::STANDARD.encode(out)
}
