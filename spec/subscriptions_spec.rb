require 'spec_helper'

describe FitgemOauth2::Client do

  let(:client) { FactoryGirl.build(:client) }
  let(:user_id) { client.user_id }
  let(:subscription_id) { 'xyz' }

  let(:subscriptions) { {} }

  describe '#subscriptions' do

    it 'gets all subscriptions' do
      url = "user/#{user_id}/apiSubscriptions.json"
      expect(client).to receive(:get_call).with(url).and_return(subscriptions)
      expect(client.subscriptions(type: :all)).to eql(subscriptions)
    end

    it 'gets sleep subscriptions' do
      url = "user/#{user_id}/sleep/apiSubscriptions.json"
      expect(client).to receive(:get_call).with(url).and_return(subscriptions)
      expect(client.subscriptions(type: :sleep)).to eql(subscriptions)
    end

    it 'gets subscriptions by id' do
      url = "user/#{user_id}/apiSubscriptions/#{subscription_id}.json"
      expect(client).to receive(:get_call).with(url).and_return(subscriptions)
      expect(client.subscriptions(subscription_id: subscription_id)).to eql(subscriptions)
    end
  end

  describe '#create_subscription' do

    it 'creates a subscription to all' do
      url = "user/#{user_id}/apiSubscriptions/#{subscription_id}.json"
      expect(client).to receive(:post_call).with(url).and_return(subscriptions)
      expect(client.create_subscription(subscription_id: subscription_id)).to eql(subscriptions)
    end

    it 'creates a subscription to a type' do
      url = "user/#{user_id}/sleep/apiSubscriptions/#{subscription_id}.json"
      expect(client).to receive(:post_call).with(url).and_return(subscriptions)
      expect(client.create_subscription(type: :sleep, subscription_id: subscription_id)).to eql(subscriptions)
    end

    it 'raises error with message' do
      connection = double
      response = double(
        status: 403,
        body: {
          errors: [
            {
              errorType: 'insufficient_scope',
              message: 'This application does not have permission to [access-type] [resource-type] data.'
            }
          ],
          success: false
        }.to_json
      )
      expect(Faraday).to receive(:new).and_return(connection)
      expect(connection).to receive(:post).and_return(response)
      expect do
        client.create_subscription(subscription_id: subscription_id)
      end.to raise_error(FitgemOauth2::ForbiddenError, JSON.parse(response.body).to_s)
    end
  end

  describe '#remove_subscription' do

    it 'creates a subscription to all' do
      url = "user/#{user_id}/apiSubscriptions/#{subscription_id}.json"
      expect(client).to receive(:delete_call).with(url).and_return(subscriptions)
      expect(client.remove_subscription(subscription_id: subscription_id)).to eql(subscriptions)
    end

    it 'creates a subscription to a type' do
      url = "user/#{user_id}/sleep/apiSubscriptions/#{subscription_id}.json"
      expect(client).to receive(:delete_call).with(url).and_return(subscriptions)
      expect(client.remove_subscription(type: :sleep, subscription_id: subscription_id)).to eql(subscriptions)
    end
  end

end
