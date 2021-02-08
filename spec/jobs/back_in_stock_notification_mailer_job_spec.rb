# frozen_string_literal: true

describe BackInStockNotificationMailerJob do
  describe '#perform' do
    subject { described_class.new(email: email, stock_location: stock_location).perform_now }
    let(:email) { bisn.email }
    let(:stock_location) { bisn.stock_location }

    let!(:store) { create(:store) }

    context "with one pending stock notification" do
      let!(:bisn) { create(:back_in_stock_notification) }

      context "item is backorderable" do
        before { bisn.variant.stock_items.update_all backorderable: true }

        it "records email was sent" do
          expect { subject }
            .to change {
              n = Spree::BackInStockNotification.find(bisn.id)
              [n.pending?, n.email_sent_count]
            }
            .from([true, 0]).to([false, 1])
        end

        it "sends the email" do
          expect{ subject }.to change { Spree::BackInStockNotificationMailer.deliveries.count }.by(1)
        end
      end

      context "item not backorderable" do

        context "item is in stock" do
          before { bisn.variant.stock_items.update_all backorderable: false, count_on_hand: 50 }

          it "sends the email" do
            expect{ subject }.to change { Spree::BackInStockNotificationMailer.deliveries.count }.by(1)
          end
        end
      end

      context "item is out of stock" do
        before { bisn.variant.stock_items.update_all backorderable: false, count_on_hand: 0 }

        it "does not send an email" do
          expect{ subject }.to_not change { Spree::BackInStockNotificationMailer.deliveries.count }
        end
      end
    end

    context "with one complete stock notification" do
      context "item is backorderable" do
        before { bisn.variant.stock_items.update_all backorderable: true }
        let!(:bisn) { create(:back_in_stock_notification, email_sent_at: 1.hour.ago) }

        it "does not send an email" do
          expect{ subject }.to_not change { Spree::BackInStockNotificationMailer.deliveries.count }
        end
      end
    end
  end
end
