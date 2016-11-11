require 'spec_helper'

describe Yt::Account do
  before(:all) do
    Yt.configuration.api_key = ''
    Yt.configuration.client_id = ENV['YT_ACCOUNT_CLIENT_ID']
    Yt.configuration.client_secret = ENV['YT_ACCOUNT_CLIENT_SECRET']
  end

  subject(:account) { Yt::Account.new refresh_token: ENV['YT_ACCOUNT_REFRESH_TOKEN'] }

  specify 'user info data can be fetched with one HTTP call' do
    expect(Net::HTTP).to receive(:start).once.with('accounts.google.com', 443, use_ssl: true).and_call_original
    expect(Net::HTTP).to receive(:start).once.with('www.googleapis.com', 443, use_ssl: true).and_call_original

    expect(account.id).to start_with '1030'
    expect(account.email).to include 'yt'
    expect(account.verified_email).to be true
    expect(account.name).to eq 'Yt Test'
    expect(account.given_name).to eq 'Yt'
    expect(account.family_name).to eq 'Test'
    expect(account.avatar_url).to end_with 'photo.jpg'
    expect(account.locale).to eq 'en'
    expect(account.hd).to be_nil
  end

  describe '#videos' do
    it 'returns the list of *public/unlisted/private* videos limiting the number of HTTP requests' do
      expect(Net::HTTP).to receive(:start).once.with('accounts.google.com', 443, use_ssl: true).and_call_original
      expect(Net::HTTP).to receive(:start).once.with('www.googleapis.com', 443, use_ssl: true).and_call_original

      expect(account.videos).to all( be_a Yt::Video )
    end

    it 'only allocates video objects the first time it is called' do
      # TODO should reallocate if .select changes the parts
      expect{account.videos.map &:itself}.to change{ObjectSpace.each_object(Yt::Video).count}
      expect{account.videos.map &:itself}.not_to change{ObjectSpace.each_object(Yt::Video).count}
    end

    it 'accepts .select to fetch multiple parts with two HTTP calls' do
      expect(Net::HTTP).to receive(:start).once.with('accounts.google.com', 443, use_ssl: true).and_call_original
      expect(Net::HTTP).to receive(:start).twice.with('www.googleapis.com', 443, use_ssl: true).and_call_original

      videos = account.videos.select :snippet, :status, :statistics, :content_details

      expect(videos).to be_present
      expect(videos.map &:title).to be
      expect(videos.map &:privacy_status).to be
      expect(videos.map &:view_count).to be
      expect(videos.map &:duration).to be
    end
  end
end
