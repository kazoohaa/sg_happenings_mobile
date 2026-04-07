class EventPosterApplicationCreatePayload {
  EventPosterApplicationCreatePayload({
    this.organization,
    this.website,
    this.description,
  });

  final String? organization;
  final String? website;
  final String? description;

  Map<String, dynamic> toJson() => {
        'organization': organization,
        'website': website,
        'description': description,
      };
}

