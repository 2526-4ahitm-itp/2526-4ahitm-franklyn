use ffmpeg_next::{codec, encoder};
use ffmpeg_next::codec::traits::Encoder;
use ffmpeg_next::format::Pixel;
use ffmpeg_next::frame::Video;
use std::path::Path;
use std::time::Instant;
use std::{thread, time::Duration};
use std::fs::metadata;
use std::io::Write;
use ffmpeg_next::codec::Context;
use ffmpeg_next::dictionary::Owned;
use ffmpeg_next::option::Type::Rational;
use xcap::Monitor;

pub fn record() {
    ffmpeg_next::init().unwrap();

    let start = Instant::now();
    let monitors = Monitor::all().unwrap();
    println!("Monitor::all() 运行耗时: {:?}", start.elapsed());

    let output_path = "out.mp4";
    let mut res_x: u32 = 1080;
    let mut res_y: u32 = 1920;
    let fps = 30;
    let bitrate = 4_000_000; // 4 Mbps

    // Create output format context for MP4
    let path = Path::new(&output_path);
    let mut octx = ffmpeg_next::format::output(&path).unwrap();

    // Find H.264 encoder
    // let codec = codec::encoder::find(codec::Id::H265)
    //     .ok_or(ffmpeg_next::Error::EncoderNotFound)
    //     .unwrap();

    let codec = encoder::find(codec::Id::H264).unwrap();



    // Create video stream
    let mut encoder = codec::context::Context::new_with_codec(codec).encoder().video().unwrap();
    let mut ost = octx.add_stream(codec).unwrap();

    for monitor in monitors {
        println!(
            "Monitor:\n id: {}\n name: {}\n position: {:?}\n size: {:?}\n state:{:?}\n",
            monitor.id().unwrap(),
            monitor.name().unwrap(),
            (monitor.x().unwrap(), monitor.y().unwrap()),
            (monitor.width().unwrap(), monitor.height().unwrap()),
            (
                monitor.rotation().unwrap(),
                monitor.scale_factor().unwrap(),
                monitor.frequency().unwrap(),
                monitor.is_primary().unwrap(),
                monitor.is_builtin().unwrap()
            )
        );

        res_x = monitor.width().unwrap();
        res_y = monitor.height().unwrap();
    }

    ost.set_parameters(&encoder);

    // Configure encoder
    encoder.set_width(res_x);
    encoder.set_height(res_y);
    encoder.set_format(Pixel::YUV420P);
    ost.set_time_base((60, fps));

    // Open encoder
    let mut opened_encoder = encoder.open_as(codec).unwrap();

    ost.set_parameters(opened_encoder);


    // Write MP4 header
    octx.write_header().unwrap();

    let mut output_frame = Video::empty();

    output_frame.set_width(res_x);
    output_frame.set_height(res_y);



    let monitor = Monitor::from_point(100, 100).unwrap();

    println!("Monitor::from_point(): {:?}", monitor.name().unwrap());
    println!(
        "Monitor::from_point(100, 100) 运行耗时: {:?}",
        start.elapsed()
    );

    println!("运行耗时: {:?}", start.elapsed());

    let monitor = Monitor::from_point(100, 100).unwrap();

    let (video_recorder, sx) = monitor.video_recorder().unwrap();

    thread::spawn(move || {
        ffmpeg_next::init().unwrap();

        let mut i = 0;

        loop {
            println!("hello");
            match sx.recv() {
                Ok(mut frame) => {
                    println!("frame: {:?}", frame.width);

                    let dst = output_frame.data_mut(i);

                    dst.copy_from_slice(frame.raw.as_slice());
                    frame.raw.write_all(dst).unwrap();
                }
                Err(e) => {
                    dbg!(e.to_string());
                }
            }
            i+=1;
        }
    });

    println!("start");
    video_recorder.start().unwrap();
    thread::sleep(Duration::from_secs(1));
    println!("stop");
    video_recorder.stop().unwrap();
    thread::sleep(Duration::from_secs(1));
    println!("start");
    video_recorder.start().unwrap();
    thread::sleep(Duration::from_secs(1));
    println!("stop");
    video_recorder.stop().unwrap();
}
