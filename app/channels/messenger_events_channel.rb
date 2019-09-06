class MessengerEventsChannel < ApplicationCable::Channel
  def subscribed
    @app  = App.find_by(key: params[:app])

    get_user_data

    if @user_data[:email].blank?
      @app_user = get_user_by_session 
    else
      @app_user = @app.app_users
                  .where("email =?", @user_data[:email])
                  .first
    end

    stream_from "messenger_events:#{@app.key}-#{@app_user.session_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def data_submit(data)
    # TODO: check permitted params here!
    data.delete('action')
    @app_user.update(data)
  end

  def send_message(options)
    options.delete("action")
    @app_user.visits.create(options)
    AppUserEventJob.perform_now(app_key: @app.key, user_id: @app_user.id)
  end


  def receive_conversation_part(data)
    @conversation = @app.conversations.find(data["conversation_id"])
    message = @conversation.messages.find(data["message_id"])
    if message.authorable != @app_user
      message.read!
    end
  end

  def request_trigger(data)
    AppUserTriggerJob.perform_now(app_key: @app.key, user_id: @app_user.id)
  end

  def track_open(data)
    @app_user.track_open(campaign_id: data["campaign_id"] )
  end

  def track_close(data)
    @app_user.track_close(campaign_id: data["campaign_id"] )
  end

  def track_click(data)
    @app_user.track_click(campaign_id: data["campaign_id"] )
  end

  def track_tour_finished(data)
    @app_user.track_finish(campaign_id: data["campaign_id"] )
  end

  def track_tour_skipped(data)
    @app_user.track_skip(campaign_id: data["campaign_id"] )
  end

end
