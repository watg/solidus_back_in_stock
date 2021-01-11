# frozen_string_literal: true

describe BackInStockNotificationEmailJob do
  describe '#perform' do
    subject { described_class.new(stock_location_params: stock_location_params).perform_now }

    let!(:store) { create(:store) }

    context "with one pending stock notification" do
      let!(:bisn) { create(:back_in_stock_notification) }

      context "item is backorderable" do
        before { bisn.variant.stock_items.update_all backorderable: true }

        context "for all stock locations" do
          let(:stock_location_params) { {} }

          it "sends the email" do
            expect { subject }
              .to change {
                n = Spree::BackInStockNotification.find(bisn.id)
                [n.pending?, n.email_sent_count]
              }
              .from([true, 0]).to([false, 1])
          end
        end

        context "for matching stock location name" do
          let(:stock_location_params) { {name: bisn.stock_location.name} }

          it "sends the email" do
            expect { subject }
              .to change { Spree::BackInStockNotification.find(bisn.id).pending? }
              .from(true).to(false)
          end
        end

        context "for matching stock location id" do
          let(:stock_location_params) { {id: bisn.stock_location.id} }

          it "sends the email" do
            expect { subject }
              .to change { Spree::BackInStockNotification.find(bisn.id).pending? }
              .from(true).to(false)
          end
        end

        context "for different stock location with different name" do
          let(:stock_location) { create(:stock_location, name: "New Stock Location" ) }
          let(:stock_location_params) { {name: stock_location.name} }

          it "does not send the email" do
            expect { subject }
              .to_not change { Spree::BackInStockNotification.find(bisn.id).pending? }
              .from(true)
          end
        end
      end

      context "item not backorderable" do

        context "item is in stock" do
          before { bisn.variant.stock_items.update_all backorderable: false, count_on_hand: 50 }

          context "for all stock locations" do
            let(:stock_location_params) { {} }

            it "sends the email" do
              expect { subject }
                .to change {
                  n = Spree::BackInStockNotification.find(bisn.id)
                  [n.pending?, n.email_sent_count]
                }
                .from([true, 0]).to([false, 1])
            end
          end
        end

        context "item is out of stock" do
          before { bisn.variant.stock_items.update_all backorderable: false, count_on_hand: 0 }

          context "for all stock locations" do
            let(:stock_location_params) { {} }

            it "sends the email" do
              expect { subject }
                .to_not change {
                  n = Spree::BackInStockNotification.find(bisn.id)
                  [n.pending?, n.email_sent_count]
                }
                .from([true, 0])
            end
          end
        end
      end
    end

    context "with one complete stock notification" do
      context "item is backorderable" do
        before { bisn.variant.stock_items.update_all backorderable: true }
        let!(:bisn) { create(:back_in_stock_notification, email_sent_at: 1.hour.ago) }

        context "for all stock locations" do
          let(:stock_location_params) { {} }

          it "does not send an email" do
            expect { subject }
              .to_not change { Spree::BackInStockNotification.find(bisn.id).email_sent_count }
          end
        end
      end
    end
  end
end
