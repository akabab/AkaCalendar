Pod::Spec.new do |spec|
  spec.name = "AkaCalendar"
  spec.version = "1.0.0"
  spec.summary = "Simple calendar view."
  spec.homepage = "https://github.com/akabab/AkaCalendar"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Akabab" => 'ycribier@student.42.fr' }

  spec.platform = :ios, "8.0"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/akabab/AkaCalendar.git", tag: "v#{spec.version}", submodules: true }
  spec.source_files = "AkaCalendar/**/*.{h,swift}"

end

