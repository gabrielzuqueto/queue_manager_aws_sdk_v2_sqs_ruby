require 'spec_helper.rb'
describe "QueueManager" do
  let(:queue_url){"https://sqs.us-west-2.amazonaws.com/943154236803/gabrielzuqueto_eti_br"}
  let(:queue_name){:gabrielzuqueto_eti_br}
  let(:client_aws_sqs){Aws::SQS::Client.new}

  before do
    allow_any_instance_of(QueueManager).to receive(:client).and_return client_aws_sqs
  end

  describe "When try instance object" do
    it "should return a new instance of QueueManager with visibility_timeout=60" do
      queue_manager = QueueManager.new(queue_name)
      expect( queue_manager.instance_eval{ queue_name } ).to eq(queue_name)
      expect( queue_manager.instance_eval{ visibility_timeout } ).to eq(60)
    end

    it "with visibility_timeout arg equals 120 should return a new instance of QueueManager with visibility_timeout=120" do
      queue_manager = QueueManager.new(queue_name, 120)
      expect( queue_manager.instance_eval{ queue_name } ).to eq(queue_name)
      expect( queue_manager.instance_eval{ visibility_timeout } ).to eq(120)
    end
  end

  describe "When call client method" do
    it "should return a instance of Aws::SQS::Client" do
      queue_manager = QueueManager.new(queue_name)
      expect( queue_manager.instance_eval{ client } ).to be_instance_of(Aws::SQS::Client)
    end
  end

  describe "When call create_queue method" do
    it "should return the queue url" do
      client_aws_sqs.stub_responses(:create_queue, queue_url: queue_url)
      queue_manager = QueueManager.new(queue_name)
      expect( queue_manager.instance_eval{ create_queue } ).to eq(queue_url)
    end
  end

  describe "When call get_queue_url method" do
    it "should return the queue url" do
      client_aws_sqs.stub_responses(:get_queue_url, queue_url: queue_url)
      queue_manager = QueueManager.new(queue_name)
      expect( queue_manager.instance_eval{ get_queue_url } ).to eq(queue_url)
    end

    it "if queue not exists should create queue and return your URL" do
      client_aws_sqs.stub_responses(:get_queue_url, 'NonExistentQueue')
      client_aws_sqs.stub_responses(:create_queue, queue_url: queue_url)
      queue_manager = QueueManager.new(queue_name)
      expect( queue_manager.instance_eval{ get_queue_url } ).to eq(queue_url)
    end
  end

  describe "When call queue_url method" do
    it "should return the queue url" do
      client_aws_sqs.stub_responses(:get_queue_url, queue_url: queue_url)
      queue_manager = QueueManager.new(queue_name)
      expect( queue_manager.instance_eval{ queue_url } ).to eq(queue_url)
    end
  end

  describe "When call send_message method" do
    it "should not return error" do
      client_aws_sqs.stub_responses(:get_queue_url, queue_url: queue_url)
      queue_manager = QueueManager.new(queue_name)
      expect { queue_manager.send_message("Something") }.to_not raise_error
    end
  end

  describe "When call receive_message method" do
    before do
      client_aws_sqs.stub_responses(:get_queue_url, queue_url: queue_url)
    end

    it "and there is no message should return response with messages array empty" do
      queue_manager = QueueManager.new(queue_name)
      expect( queue_manager.receive_message.messages.count ).to eq(0)
    end

    it "should return not empty message array" do
      client_aws_sqs.stub_responses(:receive_message, messages: [
        message_id: "Something",
        receipt_handle: "Something",
        body: {Something: "Something"}.to_json
      ])
      expected_message = [Aws::SQS::Types::Message.new(message_id: "Something", receipt_handle: "Something", body: {"Something"=>"Something"}.to_json, attributes: {}, message_attributes: {})]
      queue_manager = QueueManager.new(queue_name)
      expect(queue_manager.receive_message.messages).to eq(expected_message)
    end
  end

  describe "When call delete_message method" do
    it "should not return error" do
      client_aws_sqs.stub_responses(:get_queue_url, queue_url: queue_url)
      queue_manager = QueueManager.new(queue_name)
      expect { queue_manager.delete_message("Something") }.to_not raise_error
    end
  end

  describe "When call send_message_batch method" do
    it "should not return error" do
      client_aws_sqs.stub_responses(:get_queue_url, queue_url: queue_url)
      queue_manager = QueueManager.new(queue_name)
      expect { queue_manager.send_message_batch([{id: "1", message_body: "Something"},{id: "2", message_body: "Anything"}]) }.to_not raise_error
    end
  end

  describe "When call receive_message_batch method" do
    it "should return messages array" do
      client_aws_sqs.stub_responses(:get_queue_url, queue_url: queue_url)
      client_aws_sqs.stub_responses(:receive_message, messages: [
        {message_id: "Something",
        receipt_handle: "Something",
        body: {Something: "Something"}.to_json},
        {message_id: "Something_2",
        receipt_handle: "Something_2",
        body: {Something: "Something_2"}.to_json}
      ])

      expected_message = [
        Aws::SQS::Types::Message.new(message_id: "Something", receipt_handle: "Something", body: {"Something"=>"Something"}.to_json, attributes: {}, message_attributes: {}),
        Aws::SQS::Types::Message.new(message_id: "Something_2", receipt_handle: "Something_2", body: {"Something"=>"Something_2"}.to_json, attributes: {}, message_attributes: {})
      ]

      queue_manager = QueueManager.new(queue_name)
      expect(queue_manager.receive_message_batch.messages).to eq(expected_message)
    end
  end

  describe "When call delete_message_batch method" do
    it "should return messages array" do
      client_aws_sqs.stub_responses(:get_queue_url, queue_url: queue_url)
      queue_manager = QueueManager.new(queue_name)
      expect { queue_manager.delete_message_batch([{id: "Something", receipt_handle: "Something"}]) }.to_not raise_error
    end
  end

  describe "When call purge_queue method" do
    it "should return messages array" do
      client_aws_sqs.stub_responses(:get_queue_url, queue_url: queue_url)
      queue_manager = QueueManager.new(queue_name)
      expect { queue_manager.purge_queue }.to_not raise_error
    end
  end

  describe "When call delete_queue method" do
    it "should return messages array" do
      client_aws_sqs.stub_responses(:get_queue_url, queue_url: queue_url)
      queue_manager = QueueManager.new(queue_name)
      expect { queue_manager.delete_queue }.to_not raise_error
      expect( queue_manager.instance_eval{ @queue_url } ).to eq(nil)
    end
  end

  describe "When call " do
    before do
      client_aws_sqs.stub_responses(:get_queue_url, queue_url: queue_url)
      client_aws_sqs.stub_responses(:get_queue_attributes, attributes: {
        "ApproximateNumberOfMessages" => "1",
        "ApproximateNumberOfMessagesNotVisible" => "1",
        "ApproximateNumberOfMessagesDelayed" => "1"
      })
    end

    it "queue_size method should return queue size" do
      queue_manager = QueueManager.new(queue_name)
      expect(queue_manager.queue_size).to eq(3)
    end

    it "queue_available_size method should return queue available size" do
      queue_manager = QueueManager.new(queue_name)
      expect(queue_manager.queue_available_size).to eq(1)
    end

    it "queue_unavailable_size method should return queue unavailable size" do
      queue_manager = QueueManager.new(queue_name)
      expect(queue_manager.queue_unavailable_size).to eq(1)
    end

    it "queue_waiting_size method should return queue waiting size" do
      queue_manager = QueueManager.new(queue_name)
      expect(queue_manager.queue_waiting_size).to eq(1)
    end
  end

  describe "When call poller method" do
    it "should return a instance of Aws::SQS::QueuePoller" do
      queue_manager = QueueManager.new(queue_name)
      expect( queue_manager.poller ).to be_instance_of(Aws::SQS::QueuePoller)
    end
  end
end