RSpec.describe Spree::Admin::BackInStockNotificationsController, type: :controller do
  stub_authorization!
  let(:admin_user) { create(:admin_user) }
  before do
    allow(controller).to receive(:current_spree_user).and_return(admin_user)
  end


  describe "#index" do
    describe "GET" do
      subject { get :index }

      context "with view rendering" do
        render_views

        context "when there are not notifications" do

          it "does not raise an error" do
            expect{ subject }.to_not raise_error
          end
        end

        context "with a pending notification" do
          let!(:back_in_stock_notification) { create(:back_in_stock_notification) }

          it "shows the notification" do
            subject
            expect( response.body ).to include(back_in_stock_notification.label)
            expect( assigns(:back_in_stock_notifications) ).to eq [back_in_stock_notification]
          end

          context "when the notification user_id is nil" do
            before { back_in_stock_notification.update_column :user_id, nil }

            it "does not raise an error" do
              expect{ subject }.to_not raise_error
            end
          end
        end
      end
    end
  end
end
