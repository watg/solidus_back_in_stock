RSpec.describe Spree::BackInStockNotificationsController, type: :controller do

  describe "#create" do
    subject { post :create, params: params }

    let(:stock_notification_attributes) do
      [
        "label",
        "variant_id",
        "product_id",
        "user_id",
        "stock_location_id",
        "country_iso",
        "locale",
        "email_sent_at",
        "email_sent_count"
      ]
    end


    context "with valid params" do
      let(:variant) { create(:variant) }
      let(:email) { "bot@woolandthegang.com" }
      let(:stock_location) { variant.stock_items.first.stock_location }

      let(:params) do
        {
          back_in_stock_notification: {
            "label"=>"Perfect Peach",
            "variant_id"=>"#{variant.id}",
            "email"=>email
          }
        }
      end

      let(:session) do
        {
          stock_location_id: stock_location.id,
          locale: "en",
          country_iso: "US",
        }
      end

      before do
        allow(controller).to receive(:session).and_return(session)
      end

      context "there are no back in stock notifications" do

        context "the customer is not signed in" do
          before do
            allow(controller).to receive(:current_spree_user).and_return(nil)
          end

          it "creates a back in stock notification" do
            subject
            expect( Spree::BackInStockNotification.count ).to eq 1
            expect( Spree::BackInStockNotification.last.attributes.slice(*stock_notification_attributes) ).to eq (
              {
                "label"=>"Perfect Peach",
                "variant_id"=>variant.id,
                "product_id"=>variant.product.id,
                "user_id"=>nil,
                "stock_location_id"=>stock_location.id,
                "country_iso"=>"US",
                "locale"=>"en",
                "email_sent_at"=>nil,
                "email_sent_count"=>0
              }
            )
          end
        end

        context "the customer is signed in" do
          let(:user) { create(:user) }
          before do
            allow(controller).to receive(:current_spree_user).and_return(user)
          end

          it "creates a back in stock notification" do
            subject
            expect( Spree::BackInStockNotification.count ).to eq 1
            expect( Spree::BackInStockNotification.last.attributes.slice(*stock_notification_attributes) ).to eq (
              {
                "label"=>"Perfect Peach",
                "variant_id"=>variant.id,
                "product_id"=>variant.product.id,
                "user_id"=>user.id,
                "stock_location_id"=>stock_location.id,
                "country_iso"=>"US",
                "locale"=>"en",
                "email_sent_at"=>nil,
                "email_sent_count"=>0
              }
            )
          end
        end
      end

      context "when there is already an pending notification for the same email and variant" do
        before do
          allow(controller).to receive(:current_spree_user).and_return(nil)
        end
        let!(:back_in_stock_notification) do
          create(:back_in_stock_notification, email: email, variant: variant)
        end

        it "raises a variant taken validation error" do
          subject
          expect( assigns(:back_in_stock_notification).errors.messages[:variant] )
            .to eq [I18n.translate("activerecord.errors.models.spree/back_in_stock_notification.attributes.variant.taken")]
        end
      end

      context "when a kit product_id is provided" do
        before do
          allow(controller).to receive(:current_spree_user).and_return(nil)
        end

        let(:product) { create(:product) }
        # ensure the product id is difference to a variant id
        let(:product_id) { 123 }
        before { product.update_column :id, product_id }
        let(:params) do
          {
            back_in_stock_notification: {
              "label"=>"Perfect Peach",
              "variant_id"=>"#{variant.id}",
              "product_id"=>"#{product_id}",
              "email"=>email
            }
          }
        end

        it "saves the product_id" do
          subject
          expect( Spree::BackInStockNotification.last.attributes.slice(*stock_notification_attributes) ).to eq (
            {
              "label"=>"Perfect Peach",
              "variant_id"=>variant.id,
              "product_id"=>product.id,
              "user_id"=>nil,
              "stock_location_id"=>stock_location.id,
              "country_iso"=>"US",
              "locale"=>"en",
              "email_sent_at"=>nil,
              "email_sent_count"=>0
            }
          )
        end
      end
    end

    context "with invalid params" do
      let(:variant) { create(:variant) }
      let(:params) do
        {
          back_in_stock_notification: {"variant_id"=>"#{variant.id}"}
        }
      end
      before do
        allow(controller).to receive(:current_spree_user).and_return(nil)
      end

      it "creates an invalid draft back in stock notification" do
        subject
        expect( Spree::BackInStockNotification.count ).to eq 0
        expect( assigns(:back_in_stock_notification).valid? ).to eq false
      end
    end
  end
end
