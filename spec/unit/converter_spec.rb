require 'spec_helper'
require 'pathname'
require 'middleman-core'
require_relative '../../lib/middleman-webp/converter'

describe Middleman::WebP::Converter do
  before do
    @app_mock = stub(inst: stub(build_dir: 'spec/fixtures/dummy-build'))
    @converter = Middleman::WebP::Converter.new(@app_mock, {}, nil)
  end

  describe '#destination_path' do
    it 'returns file name with same basename and webp suffix' do
      d = @converter.destination_path(Pathname.new('build/images/sample.jpg'))
      d.to_s.must_equal 'build/images/sample.webp'
    end
  end

  describe '#destination_path with append_extension = true' do
    before do
      @converter = Middleman::WebP::Converter.new(@app_mock, {append_extension: true}, nil)
    end

    it 'returns file name with same basename and webp suffix' do
      d = @converter.destination_path(Pathname.new('build/images/sample.jpg'))
      d.to_s.must_equal 'build/images/sample.jpg.webp'
    end
  end

  describe '#change_percentage' do
    it 'returns how many percents smaller destination file is' do
      @converter.change_percentage(10_000, 8746).must_equal '12.54 %'
    end

    it 'omits zeroes in the end of decimal part' do
      @converter.change_percentage(100, 76).must_equal '24 %'
    end

    it 'returns 0% when original and new size are both 0' do
      @converter.change_percentage(0, 0).must_equal '0 %'
    end
  end

  describe '#number_to_human_size' do
    it 'uses human readable unit' do
      @converter.number_to_human_size(100).must_equal '100 B'
      @converter.number_to_human_size(1234).must_equal '1.21 KiB'
      @converter.number_to_human_size(2_634_234).must_equal '2.51 MiB'
    end

    it 'handles zero size properly' do
      @converter.number_to_human_size(0).must_equal '0 B'
    end
  end

  describe '#tool_for' do
    it 'uses gif2webp for gif files' do
      path = Pathname.new('/some/path/image.gif')
      @converter.tool_for(path).must_equal 'gif2webp'
    end

    it 'uses cwebp for jpeg, png and tiff files' do
      path = Pathname.new('/some/path/image.jpg')
      @converter.tool_for(path).must_equal 'cwebp'
      path = Pathname.new('/some/path/image.png')
      @converter.tool_for(path).must_equal 'cwebp'
      path = Pathname.new('/some/path/image.tiff')
      @converter.tool_for(path).must_equal 'cwebp'
    end
  end

  describe '#image_files' do
    it 'includes all image files in Middleman build dir' do
      @converter.image_files.size.must_equal 3
    end

    it 'won\'t include ignored files' do
      @converter = Middleman::WebP::Converter.new(@app_mock, {
                                                    ignore: [/jpg$/, '**/*.gif']
                                                  }, nil)

      files_to_include = [Pathname.new('spec/fixtures/dummy-build/empty.png')]
      @converter.image_files.must_equal files_to_include
    end

    it 'won\'t include files rejected by given proc' do
      options = {
        ignore: ->(path) { path.end_with? 'jpg' }
      }
      @converter = Middleman::WebP::Converter.new(@app_mock, options, nil)

      @converter.image_files.size.must_equal 2
    end
  end
end
