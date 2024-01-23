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

      context "format CSV" do
        subject { get :index, params: {format: :csv} }

        let!(:bisn) { create(:back_in_stock_notification) }
        let(:stock_location) { bisn.stock_location }
        let(:product) { bisn.product }
        let(:variant) { bisn.variant }


        it "returns the expected CSV contents" do
          subject
          expect( CSV.parse(response.body) ).to eq (
            [
              ["id",          "product",              "label",         "product_sku",    "variant_sku",    "stock_location",         "country_iso", "locale", "email_sent_count"],
              ["#{bisn.id}",  "#{bisn.product_name}", "Perfect Peach", "#{product.sku}", "#{variant.sku}", "#{stock_location.name}", "GB",          "en",     "0"]
            ]
          )
        end
      end
    end
  end

  describe "#summary" do
    describe "GET" do
      subject { get :summary, params: params }
      let(:params) { {} }

      context "with view rendering" do
        render_views

        context "with one USA and two UK pending requests" do
          let!(:usa_stock_location) { create(:stock_location, name: "DmcUsa") }
          let!(:uk_stock_location) { create(:stock_location, name: "WATG - LDN") }

          context "USA request for one variant and both UK requests for another variant" do
            let!(:variant_1) { create(:variant, sku: "V1") }
            let!(:variant_2) { create(:variant, sku: "V2") }
            let!(:us_back_in_stock_notification) do
              create(:back_in_stock_notification,
                variant: variant_1,
                stock_location: usa_stock_location,
                email: "customer1@email.com")
            end
            let!(:uk_back_in_stock_notification_1) do
              create(:back_in_stock_notification,
                variant: variant_2,
                stock_location: uk_stock_location,
                email: "customer2@email.com")
            end
            let!(:uk_back_in_stock_notification_2) do
              create(:back_in_stock_notification,
                variant: variant_2,
                stock_location: uk_stock_location,
                email: "customer3@email.com")
            end

            context "with no filtering" do

              it "returns the expected results" do
                subject
                expect(assigns(:back_in_stock_notifications_summary)).to eq [[variant_2, 2], [variant_1, 1]]
              end

              context "order by sku" do
                let(:params) { {sort_by: :sku} }

                it "returns the expected results ordered by sku" do
                  subject
                  expect(assigns(:back_in_stock_notifications_summary)).to eq [[variant_1, 1], [variant_2, 2]]
                end
              end
            end

            context "filter by UK stock location" do
              let(:params) { {q: {stock_location_id_eq: uk_stock_location.id}} }

              it "returns the expected results" do
                subject
                expect(assigns(:back_in_stock_notifications_summary)).to eq [[variant_2, 2]]
              end
            end

            context "requested 0, 2, and 4 days ago" do
              before do
                uk_back_in_stock_notification_1.update_column :updated_at, 2.days.ago
                uk_back_in_stock_notification_2.update_column :updated_at, 4.days.ago
              end

              context "filter by start date of three days ago" do
                let(:params) { {q: {updated_at_gt: 3.days.ago.strftime("%Y-%m-%d")}} }

                context "with no end date" do
                  it "returns the results from two requests" do
                    subject
                    expect(assigns(:back_in_stock_notifications_summary)).to match_array [[variant_2, 1], [variant_1, 1]]
                  end
                end

                context "with an end date of yesterday" do
                  before do
                    params[:q][:updated_at_lt] = 1.day.ago.strftime("%Y-%m-%d")
                  end

                  it "returns the results from 1 request" do
                    subject
                    expect(assigns(:back_in_stock_notifications_summary)).to eq [[variant_2, 1]]
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
