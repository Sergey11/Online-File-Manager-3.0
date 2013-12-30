require 'spec_helper'

describe Item do
  
  describe 'methods' do
    it 'should return right name' do
      host = 'railsforum.com'
      url1 = 'http://railsforum.com'
      url2 = 'http://railsforum.com/'
      url3 = 'http://railsforum.com/some_path'
      url4 = 'http://railsforum.com/some_path.png'

      Item.file_name(url1, host).should eq("index.html")
      Item.file_name(url2, host).should eq("index.html")
      Item.file_name(url3, host).should eq("some_path")
      Item.file_name(url4, host).should eq("some_path.png")
    end

    it 'should return file extension' do
      file1 = FactoryGirl.create(:item, file_file_name: 'new1.txt')
      file2 = FactoryGirl.create(:item, file_file_name: 'new2.Txt')
      file3 = FactoryGirl.create(:item, file_file_name: 'new3.mp3.TXT')
      file4 = FactoryGirl.create(:item, file_file_name: 'SOMEfile')

      file1.extension.should eq('txt')
      file2.extension.should eq('txt')
      file3.extension.should eq('txt')
      file4.extension.should eq('')
    end
  end

end
