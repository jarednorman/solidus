require 'spec_helper'
require 'spree/promo/coupon_applicator'

module Spree
  describe Api::CheckoutsController do
    render_views

    before(:each) do
      stub_authentication!
      Spree::Config[:track_inventory_levels] = false
      country_zone = create(:zone, :name => 'CountryZone')
      @state = create(:state)
      @country = @state.country
      country_zone.members.create(:zoneable => @country)

      @shipping_method = create(:shipping_method, :zone => country_zone)
      @payment_method = create(:payment_method)
    end

    after do
      Spree::Config[:track_inventory_levels] = true
    end

    context "POST 'create'" do
      it "creates a new order when no parameters are passed" do
        api_post :create

        json_response['number'].should be_present
        response.status.should == 201
      end

      it "should not have a user by default" do
        api_post :create

        json_response['user_id'].should_not be_present
        response.status.should == 201
      end

      it "should not have an email by default" do
        api_post :create

        json_response['email'].should_not be_present
        response.status.should == 201
      end
    end

    context "PUT 'update'" do
      let(:order) { create(:order) }

      before(:each) do
        Order.any_instance.stub(:confirmation_required? => true)
        Order.any_instance.stub(:payment_required? => true)
      end

      it "will return an error if the recently created order cannot transition from cart to address" do
        order.state.should eq "cart"
        order.update_column(:email, nil) # email is necessary to transition from cart to address

        api_put :update, :id => order.to_param

        # Order has not transitioned
        json_response['state'].should == 'cart'
      end

      it "should transition a recently created order from cart do address" do
        order.state.should eq "cart"
        order.email.should_not be_nil
        api_put :update, :id => order.to_param
        order.reload.state.should eq "address"
      end

      it "will return an error if the order cannot transition" do
        order.update_column(:state, "address")
        api_put :update, :id => order.to_param
        json_response['error'].should =~ /could not be transitioned/
        response.status.should == 422
      end

      it "can update addresses and transition from address to delivery" do
        order.update_column(:state, "address")
        shipping_address = billing_address = {
          :firstname  => 'John',
          :lastname   => 'Doe',
          :address1   => '7735 Old Georgetown Road',
          :city       => 'Bethesda',
          :phone      => '3014445002',
          :zipcode    => '20814',
          :state_id   => @state.id,
          :country_id => @country.id
        }
        api_put :update,
                :id => order.to_param,
                :order => { :bill_address_attributes => billing_address, :ship_address_attributes => shipping_address }

        json_response['state'].should == 'delivery'
        json_response['bill_address']['firstname'].should == 'John'
        json_response['ship_address']['firstname'].should == 'John'
        response.status.should == 200
      end

      it "can update shipping method and transition from delivery to payment" do
        order.update_column(:state, "delivery")
        api_put :update, :id => order.to_param, :order => { :shipping_method_id => @shipping_method.id }

        json_response['shipments'][0]['shipping_method']['name'].should == @shipping_method.name
        json_response['state'].should == 'payment'
        response.status.should == 200
      end

      it "can update payment method and transition from payment to confirm" do
        order.update_column(:state, "payment")
        api_put :update, :id => order.to_param, :order => { :payments_attributes => [{ :payment_method_id => @payment_method.id }] }
        json_response['state'].should == 'confirm'
        json_response['payments'][0]['payment_method']['name'].should == @payment_method.name
        response.status.should == 200
      end

      it "can transition from confirm to complete" do
        order.update_column(:state, "confirm")
        Spree::Order.any_instance.stub(:payment_required? => false)
        api_put :update, :id => order.to_param
        json_response['state'].should == 'complete'
        response.status.should == 200
      end

      it "returns the order if the order is already complete" do
        order.update_column(:state, "complete")
        api_put :update, :id => order.to_param
        json_response['number'].should == order.number
        response.status.should == 200
      end

      context "as an admin" do
        sign_in_as_admin!
        it "can assign a user to the order" do
          user = create(:user)
          # Need to pass email as well so that validations succeed
          api_put :update, :id => order.to_param, :order => { :user_id => user.id, :email => "guest@spreecommerce.com" }
          response.status.should == 200
          json_response['user_id'].should == user.id
        end
      end

      it "can assign an email to the order" do
        api_put :update, :id => order.to_param, :order => { :email => "guest@spreecommerce.com" }
        json_response['email'].should == "guest@spreecommerce.com"
        response.status.should == 200
      end

      it "can apply a coupon code to an order" do
        order.update_column(:state, "payment")
        Spree::Promo::CouponApplicator.should_receive(:new).with(order).and_call_original
        Spree::Promo::CouponApplicator.any_instance.should_receive(:apply)
        api_put :update, :id => order.to_param, :order => { :coupon_code => "foobar" }
      end
    end

    context "PUT 'next'" do
      let!(:order) { create(:order) }
      it "can transition an order to the next state" do
        order.update_column(:email, "spree@example.com")

        api_put :next, :id => order.to_param
        response.status.should == 200
        json_response['state'].should == 'address'
      end

      it "cannot transition if order email is blank" do
        order.update_column(:email, nil)

        api_put :next, :id => order.to_param
        response.status.should == 422
        json_response['error'].should =~ /could not be transitioned/
      end
    end
  end
end
