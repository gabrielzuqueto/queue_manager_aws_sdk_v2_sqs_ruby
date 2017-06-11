class QueueManager
  def initialize(queue_name, visibility_timeout = 60)
    @queue_name = queue_name
    @visibility_timeout = visibility_timeout
  end

  def send_message(message_data)
    client.send_message({queue_url: queue_url, message_body: message_data })
  end

  def receive_message
    client.receive_message({queue_url: queue_url, visibility_timeout: visibility_timeout})
  end

  def delete_message(message_handle)
    client.delete_message({queue_url: queue_url, receipt_handle: message_handle})
  end

  def send_message_batch(batch_data = [])
    client.send_message_batch({queue_url: queue_url, entries: batch_data})
  end

  def receive_message_batch(batch_size = 10)
    client.receive_message({queue_url: queue_url, max_number_of_messages: batch_size, visibility_timeout: visibility_timeout})
  end

  def delete_message_batch(batch_data = [])
    client.delete_message_batch({queue_url: queue_url, entries: batch_data})
  end

  def purge_queue
    client.purge_queue({queue_url: queue_url})
  end

  def delete_queue
    client.delete_queue({queue_url: queue_url})
    @queue_url = nil
  end

  def queue_size
    response = client.get_queue_attributes({queue_url: queue_url, attribute_names: ["ApproximateNumberOfMessages", "ApproximateNumberOfMessagesNotVisible", "ApproximateNumberOfMessagesDelayed"]})
    response.attributes["ApproximateNumberOfMessages"].to_i + response.attributes["ApproximateNumberOfMessagesNotVisible"].to_i + response.attributes["ApproximateNumberOfMessagesDelayed"].to_i
  end

  def queue_available_size
    response = client.get_queue_attributes({queue_url: queue_url, attribute_names: ["ApproximateNumberOfMessages"]})
    response.attributes["ApproximateNumberOfMessages"].to_i
  end

  def queue_unavailable_size
    response = client.get_queue_attributes({queue_url: queue_url, attribute_names: ["ApproximateNumberOfMessagesNotVisible"]})
    response.attributes["ApproximateNumberOfMessagesNotVisible"].to_i
  end

  def queue_waiting_size
    response = client.get_queue_attributes({queue_url: queue_url, attribute_names: ["ApproximateNumberOfMessagesDelayed"]})
    response.attributes["ApproximateNumberOfMessagesDelayed"].to_i
  end

  def poller
    @queue_poller ||= Aws::SQS::QueuePoller.new(queue_url, {max_number_of_messages:10, skip_delete: true, wait_time_seconds: nil, visibility_timeout: visibility_timeout})
  end

  private
  def client
    @client ||= Aws::SQS::Client.new
  end

  def visibility_timeout
    @visibility_timeout
  end

  def queue_name
    @queue_name
  end

  def queue_url
    @queue_url ||= get_queue_url
  end

  def get_queue_url
    begin
      client.get_queue_url({queue_name: queue_name}).queue_url
    rescue Aws::SQS::Errors::NonExistentQueue
      create_queue
    end
  end

  def create_queue
    client.create_queue({queue_name: queue_name},{:http_open_timeout => 3600, :http_read_timeout => 3600, :logger => nil, :visibility_timeout => 60}).queue_url
  end
end