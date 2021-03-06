require 'spec_helper'

describe ItemsController do

  login_user
  render_views

  let(:item) { FactoryGirl.create(:item) }
  let(:folder) { FactoryGirl.create(:folder) }
  let(:item_with_file) { FactoryGirl.create(:item, folder_id: folder.id, :file => fixture_file_upload('/test.jpg', 'text/csv')) }

  describe 'GET #crop_image' do
    it 'should find image' do 
      get :crop_image, {:id => item.id}
      assigns(:image).should eq(item)
      expect(response).to be_success
    end
  end

  describe 'GET #show_pdf' do
    it 'should show the pdf' do
      get :show_pdf, {:id => item_with_file.id}
      expect(response).to redirect_to item_with_file.file.url
    end
  end

  describe 'GET #pdf' do
    it 'should show the pdf' do
      instance = stub(:to_pdf => true)
      PdfFormater.expects(:new).returns(instance)
      get :pdf, {:id => item.id}
      expect(response).not_to be_success
    end
  end

  describe 'PdfFormater' do
    it 'should do something' do
      item_with_csv = FactoryGirl.create(:item, folder_id: folder.id, :file => fixture_file_upload('/test.csv', 'text/csv'))
      response = PdfFormater.new.to_pdf(item_with_csv.file.url)
      expect(response).not_to eq ''
    end
  end

  describe 'POST #crop_process' do
    it 'should reprocess image' do
      post :crop_process, {:id => item_with_file.id, :item => {:crop_x => '12', :crop_y => '12', :crop_w => '12', :crop_h => '23'}}
      assigns(:image).should eq(item_with_file)
      expect(response).to redirect_to folder
    end
  end

  describe 'GET #import_page' do
    let(:folder) {FactoryGirl.create(:folder)}
    it 'should import a link and redirect to folder' do
      resp = stub(:body => 'awesome content')
      HTTParty.expects(:get).with('http://somedomain.com/user.aspx').returns(resp)
      expect{
        get :import_page, {folder_id: folder.id, :import => {:folder_id => folder.id, :url => 'http://somedomain.com/user.aspx'}}
      }.to change(Item, :count).by(1)
      expect(response).to redirect_to folder
    end


    it 'should import a link and redirect to root' do
      resp = stub(:body => 'awesome content')
      HTTParty.expects(:get).with('http://somedomain.com/user.aspx').returns(resp)
      expect{
        get :import_page, {:import => {:folder_id => folder.id, :url => 'http://somedomain.com/user.aspx'}}
      }.to change(Item, :count).by(1)
      expect(response).to redirect_to root_path
    end

    it 'should fail gracefully' do
      resp = stub(:body => 'awesome content')
      get :import_page, {:import => {:folder_id => folder.id, :url => 'incorrect url'}}
      expect(response).to redirect_to import_pages_items_path
    end
  end

  describe 'GET #send_mail' do
    it 'should send mail' do
      mailer = stub(:deliver => true)
      FileManagerMailer.expects(:send_file).with(
        'john@somedomain.com',
        'Hello John!',
        item.file.url,
        item.file_file_name
      ).returns(mailer)
      get :send_mail, {:id => item.id, :email_validator => {:recipient => 'john@somedomain.com', :subject => 'Hello John!'}}
      expect(response).to redirect_to(item.folder)
    end
  end

  describe 'GET #add_recipient' do
    it 'should find item' do 
      get :add_recipient, {:id => item.id}
      assigns(:item).should eq(item)
      response.should be_success
    end
  end

  describe 'GET new' do
    it 'should render new' do
      get :new
      response.should be_success
      response.should render_template :new
    end

    it 'should render new with folder id' do
      folder = FactoryGirl.create(:folder)
      get :new, :folder_id => folder.id
      response.should be_success
      response.should render_template :new
    end
  end

  describe "DELETE destroy" do
    it "delete item" do
      sign_in :user, item.user
      request.env["HTTP_REFERER"]="/" 
      expect{delete :destroy, id: item.id}.to change(Item,:count).by(-1) 
    end
  end

  describe 'POST create' do
    it 'create new item without folder' do
      file =  fixture_file_upload('/test.csv', 'text/csv')
      item = {folder_id: nil, :file => file } 
      expect{ post :create, item: item }.to change(Item,:count).by(1)
    end

    it 'create new item with folder' do
      file =  fixture_file_upload('/test.csv', 'text/csv')
      item = {folder_id: folder.id, :file => file } 
      expect{ post :create, item: item }.to change(Item,:count).by(1)
      folder.items.should have(1).item
    end

    it 'create new item with folder' do 
      expect{ post :create, item: FactoryGirl.attributes_for(:item, file_file_name: nil) }.to change(Item,:count).by(0)
    end

    it "should not create item when quota is overflowed" do
      file =  fixture_file_upload('/test.csv', 'text/csv')
      item = {folder_id: folder.id, :file => file}
      User.any_instance.stubs(:space_used).returns(1000)
      User.any_instance.stubs(:quota).returns(100)
      expect{ post :create, item: item }.to change(Item,:count).by(0)
      response.should render_template :new
    end
  end

  describe "PUT update" do
    let!(:old_item) {FactoryGirl.create(:item, :file_file_name =>"123123")}
    let!(:folder) {FactoryGirl.create(:folder, parent_id: Folder.first.id)}
    describe "valid attributes" do
      it "update item" do
        file =  fixture_file_upload('/test.csv', 'text/csv')
        item = {folder_id: folder.id, :file => file } 
        sign_in :user, old_item.user
        put :update, {id: old_item.id, item: item}
        old_item.reload
        old_item.file_file_name.should eq("test.csv")
        expect(flash).not_to be_nil
        expect(response).to redirect_to old_item.folder
      end
    end

    describe "invalid attributes" do
      it "should not update item" do
        item = {folder_id: folder.id, :file => nil} 
        sign_in :user, old_item.user
        put :update, {id: old_item.id, item: item}
        old_item.reload
        old_item.file_file_name.should eq("123123")
      end

      it "should not update item" do
        request.env["HTTP_REFERER"] = 'where_i_came_from'
        item = {folder_id: folder.id, :file => nil} 
        put :update, {id: old_item.id, item: item}
        expect(response).to redirect_to('where_i_came_from')
        old_item.reload
        old_item.file_file_name.should eq("123123")
      end
    end
  end

  describe 'GET edit' do
    it 'should render edit' do
      sign_in :user, item.user
      get :edit, id: item.id
      response.should be_success
      response.should render_template :edit
    end
  end

  describe "GET duplicates with duplicate files" do
    let!(:item1){FactoryGirl.create(:item, file_file_name: '1.txt',:folder => FactoryGirl.create(:folder))}
    let!(:item2){FactoryGirl.create(:item, file_file_name: '1.txt',:folder => FactoryGirl.create(:folder))}
    it "assigns all Item.duplicates as @items and find duplicates" do
      get :duplicates
      response.should be_success
      response.body.should have_content("1.txt")
    end
  end

  describe "GET duplicates without any duplicate files" do
    it "assigns all Item.duplicates as @items and cannot find any duplicates" do
      get :duplicates
      response.should be_success
      response.body.should have_content("There are no duplicate files")
    end
  end
  
end
