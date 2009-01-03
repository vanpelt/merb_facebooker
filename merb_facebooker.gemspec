Gem::Specification.new do |s|
  s.name = "merb_facebooker"
  s.version = "0.0.2"
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE", 'TODO']
  s.summary = "Merb plugin that makes rfacebooker work with merb..."
  s.description = s.summary
  s.author = "Chris Van Pelt"
  s.email = "vanpelt@doloreslabs.com"
  s.homepage = "http://merb-plugins.rubyforge.org/merb_facebooker/"
  s.add_dependency('merb-core', '>= 0.9.4')
  s.add_dependency('facebooker')
  s.require_path = 'lib'
  s.autorequire = "merb_facebooker"
  s.files = %w(LICENSE README Rakefile TODO) + Dir.glob("{lib,specs}/**/*")
end