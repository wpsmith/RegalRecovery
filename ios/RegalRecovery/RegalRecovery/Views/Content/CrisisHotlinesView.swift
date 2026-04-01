import SwiftUI

struct CrisisHotlinesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(ContentData.crisisResources) { resource in
                    RRCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(resource.name)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)

                            Text(resource.phone)
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(Color.rrPrimary)

                            Text(resource.description)
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.rrPrimary)

                        Text("What is SA?")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)

                        Text("Sexaholics Anonymous (SA) is a 12-step fellowship for those who want to stop their sexually self-destructive thinking and behavior. SA defines sobriety as no sex with self and no sex with anyone other than spouse.")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .background(Color.rrBackground)
    }
}

#Preview {
    NavigationStack {
        CrisisHotlinesView()
    }
}
